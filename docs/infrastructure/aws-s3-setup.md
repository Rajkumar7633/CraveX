# AWS S3 Setup Guide for CraveX

This guide explains how to set up and configure AWS S3 for file storage in the CraveX food delivery platform.

## Overview

AWS S3 will be used for:
- **Restaurant Images**: Store restaurant logos, cover photos, and food images
- **User Avatars**: Store user profile pictures
- **Rider Documents**: Store rider verification documents (license, ID proof)
- **Menu Images**: Store menu item images
- **Reports**: Store generated reports and analytics exports
- **Backups**: Store database backups and logs

## Prerequisites

- AWS Account with appropriate permissions
- AWS CLI installed and configured
- AWS credentials configured

## AWS Setup

### Create S3 Bucket

```bash
# Create bucket
aws s3 mb s3://cravex-storage

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket cravex-storage \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket cravex-storage \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

# Set up lifecycle policy
aws s3api put-bucket-lifecycle-configuration \
  --bucket cravex-storage \
  --lifecycle-configuration file://lifecycle-policy.json
```

### Create Folders

```bash
# Create folder structure
aws s3api put-object --bucket cravex-storage --key restaurants/
aws s3api put-object --bucket cravex-storage --key users/
aws s3api put-object --bucket cravex-storage --key riders/
aws s3api put-object --bucket cravex-storage --key menu/
aws s3api put-object --bucket cravex-storage --key reports/
aws s3api put-object --bucket cravex-storage --key backups/
```

### Lifecycle Policy

Create `lifecycle-policy.json`:

```json
{
  "Rules": [
    {
      "ID": "DeleteOldBackups",
      "Filter": {
        "Prefix": "backups/"
      },
      "Status": "Enabled",
      "Expiration": {
        "Days": 90
      }
    },
    {
      "ID": "DeleteOldReports",
      "Filter": {
        "Prefix": "reports/"
      },
      "Status": "Enabled",
      "Expiration": {
        "Days": 30
      }
    },
    {
      "ID": "TransitionToIA",
      "Filter": {
        "Prefix": ""
      },
      "Status": "Enabled",
      "Transitions": [
        {
          "Days": 30,
          "StorageClass": "STANDARD_IA"
        },
        {
          "Days": 90,
          "StorageClass": "GLACIER"
        }
      ]
    }
  ]
}
```

## IAM Policy

Create IAM policy for S3 access:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::cravex-storage",
        "arn:aws:s3:::cravex-storage/*"
      ]
    }
  ]
}
```

## Go Integration

### Install AWS SDK

```bash
go get github.com/aws/aws-sdk-go-v2
go get github.com/aws/aws-sdk-go-v2/config
go get github.com/aws/aws-sdk-go-v2/service/s3
```

### S3 Client Implementation

Create `backend/pkg/storage/s3_client.go`:

```go
package storage

import (
	"context"
	"fmt"
	"io"
	"log"
	"mime/multipart"
	"strings"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/s3"
)

type S3Client struct {
	client *s3.Client
	bucket string
}

func NewS3Client(ctx context.Context, bucket, region string) (*S3Client, error) {
	cfg, err := config.LoadDefaultConfig(ctx, config.WithRegion(region))
	if err != nil {
		return nil, fmt.Errorf("failed to load AWS config: %w", err)
	}

	client := s3.NewFromConfig(cfg)

	return &S3Client{
		client: client,
		bucket: bucket,
	}, nil
}

func (s *S3Client) UploadFile(ctx context.Context, key string, file multipart.File, contentType string) (string, error) {
	defer file.Close()

	// Get file size
	fileInfo, err := file.Stat()
	if err != nil {
		return "", fmt.Errorf("failed to get file info: %w", err)
	}

	// Upload to S3
	_, err = s.client.PutObject(ctx, &s3.PutObjectInput{
		Bucket:      aws.String(s.bucket),
		Key:         aws.String(key),
		Body:        file,
		ContentType: aws.String(contentType),
		ACL:         s3.ObjectCannedACLPrivate,
		Metadata: map[string]string{
			"uploaded-at": time.Now().Format(time.RFC3339),
		},
	})

	if err != nil {
		return "", fmt.Errorf("failed to upload file: %w", err)
	}

	// Generate presigned URL
	url, err := s.GetPresignedURL(ctx, key, 24*time.Hour)
	if err != nil {
		return "", fmt.Errorf("failed to generate presigned URL: %w", err)
	}

	return url, nil
}

func (s *S3Client) UploadBytes(ctx context.Context, key string, data []byte, contentType string) (string, error) {
	_, err := s.client.PutObject(ctx, &s3.PutObjectInput{
		Bucket:      aws.String(s.bucket),
		Key:         aws.String(key),
		Body:        bytes.NewReader(data),
		ContentType: aws.String(contentType),
		ACL:         s3.ObjectCannedACLPrivate,
	})

	if err != nil {
		return "", fmt.Errorf("failed to upload bytes: %w", err)
	}

	url, err := s.GetPresignedURL(ctx, key, 24*time.Hour)
	if err != nil {
		return "", fmt.Errorf("failed to generate presigned URL: %w", err)
	}

	return url, nil
}

func (s *S3Client) GetFile(ctx context.Context, key string) ([]byte, error) {
	result, err := s.client.GetObject(ctx, &s3.GetObjectInput{
		Bucket: aws.String(s.bucket),
		Key:    aws.String(key),
	})

	if err != nil {
		return nil, fmt.Errorf("failed to get file: %w", err)
	}
	defer result.Body.Close()

	data, err := io.ReadAll(result.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read file: %w", err)
	}

	return data, nil
}

func (s *S3Client) DeleteFile(ctx context.Context, key string) error {
	_, err := s.client.DeleteObject(ctx, &s3.DeleteObjectInput{
		Bucket: aws.String(s.bucket),
		Key:    aws.String(key),
	})

	if err != nil {
		return fmt.Errorf("failed to delete file: %w", err)
	}

	return nil
}

func (s *S3Client) GetPresignedURL(ctx context.Context, key string, expiration time.Duration) (string, error) {
	presignClient := s3.NewPresignClient(s.client)

	presignedResult, err := presignClient.PresignGetObject(ctx, &s3.GetObjectInput{
		Bucket: aws.String(s.bucket),
		Key:    aws.String(key),
	}, s3.WithPresignExpires(expiration))

	if err != nil {
		return "", fmt.Errorf("failed to generate presigned URL: %w", err)
	}

	return presignedResult.URL, nil
}

func (s *S3Client) ListFiles(ctx context.Context, prefix string) ([]string, error) {
	result, err := s.client.ListObjectsV2(ctx, &s3.ListObjectsV2Input{
		Bucket: aws.String(s.bucket),
		Prefix: aws.String(prefix),
	})

	if err != nil {
		return nil, fmt.Errorf("failed to list files: %w", err)
	}

	var keys []string
	for _, obj := range result.Contents {
		keys = append(keys, *obj.Key)
	}

	return keys, nil
}

func (s *S3Client) CopyFile(ctx context.Context, sourceKey, destKey string) error {
	_, err := s.client.CopyObject(ctx, &s3.CopyObjectInput{
		Bucket:     aws.String(s.bucket),
		CopySource: aws.String(fmt.Sprintf("%s/%s", s.bucket, sourceKey)),
		Key:        aws.String(destKey),
	})

	if err != nil {
		return fmt.Errorf("failed to copy file: %w", err)
	}

	return nil
}
```

### Storage Service Implementation

Create `backend/pkg/storage/storage_service.go`:

```go
package storage

import (
	"context"
	"fmt"
	"path/filepath"
	"strings"
	"time"

	"github.com/google/uuid"
)

type StorageService struct {
	s3 *S3Client
}

func NewStorageService(s3 *S3Client) *StorageService {
	return &StorageService{s3: s3}
}

// Upload restaurant image
func (s *StorageService) UploadRestaurantImage(ctx context.Context, restaurantID string, file multipart.File, contentType string) (string, error) {
	ext := strings.Split(contentType, "/")[1]
	key := fmt.Sprintf("restaurants/%s/%s.%s", restaurantID, uuid.New().String(), ext)
	return s.s3.UploadFile(ctx, key, file, contentType)
}

// Upload user avatar
func (s *StorageService) UploadUserAvatar(ctx context.Context, userID string, file multipart.File, contentType string) (string, error) {
	ext := strings.Split(contentType, "/")[1]
	key := fmt.Sprintf("users/%s/avatar.%s", userID, ext)
	return s.s3.UploadFile(ctx, key, file, contentType)
}

// Upload rider document
func (s *StorageService) UploadRiderDocument(ctx context.Context, riderID, docType string, file multipart.File, contentType string) (string, error) {
	ext := strings.Split(contentType, "/")[1]
	key := fmt.Sprintf("riders/%s/%s/%s.%s", riderID, docType, uuid.New().String(), ext)
	return s.s3.UploadFile(ctx, key, file, contentType)
}

// Upload menu item image
func (s *StorageService) UploadMenuItemImage(ctx context.Context, restaurantID, menuItemID string, file multipart.File, contentType string) (string, error) {
	ext := strings.Split(contentType, "/")[1]
	key := fmt.Sprintf("menu/%s/%s/%s.%s", restaurantID, menuItemID, uuid.New().String(), ext)
	return s.s3.UploadFile(ctx, key, file, contentType)
}

// Upload report
func (s *StorageService) UploadReport(ctx context.Context, reportType, date string, data []byte) (string, error) {
	key := fmt.Sprintf("reports/%s/%s-%s.csv", reportType, date, uuid.New().String())
	return s.s3.UploadBytes(ctx, key, data, "text/csv")
}

// Delete restaurant image
func (s *StorageService) DeleteRestaurantImage(ctx context.Context, key string) error {
	return s.s3.DeleteFile(ctx, key)
}

// Get restaurant image URL
func (s *StorageService) GetRestaurantImageURL(ctx context.Context, key string) (string, error) {
	return s.s3.GetPresignedURL(ctx, key, 24*time.Hour)
}

// List restaurant images
func (s *StorageService) ListRestaurantImages(ctx context.Context, restaurantID string) ([]string, error) {
	prefix := fmt.Sprintf("restaurants/%s/", restaurantID)
	return s.s3.ListFiles(ctx, prefix)
}
```

## Service Integration

### Restaurant Service Integration

```go
package main

import (
	"context"
	"log"
	"os"
	
	"github.com/zomato-clone/pkg/storage"
)

func main() {
	// Initialize S3 Client
	ctx := context.Background()
	s3Client, err := storage.NewS3Client(ctx, os.Getenv("S3_BUCKET"), os.Getenv("AWS_REGION"))
	if err != nil {
		log.Fatalf("Failed to create S3 client: %v", err)
	}

	storageService := storage.NewStorageService(s3Client)

	// Upload restaurant image
	file, err := os.Open("restaurant-image.jpg")
	if err != nil {
		log.Fatalf("Failed to open file: %v", err)
	}

	url, err := storageService.UploadRestaurantImage(ctx, "REST123", file, "image/jpeg")
	if err != nil {
		log.Fatalf("Failed to upload image: %v", err)
	}

	log.Printf("Image uploaded successfully: %s", url)
}
```

### HTTP Handler for Upload

```go
package handlers

import (
	"net/http"
	
	"github.com/zomato-clone/pkg/storage"
)

type UploadHandler struct {
	storage *storage.StorageService
}

func NewUploadHandler(storage *storage.StorageService) *UploadHandler {
	return &UploadHandler{storage: storage}
}

func (h *UploadHandler) UploadRestaurantImage(c *gin.Context) {
	restaurantID := c.Param("restaurant_id")
	
	file, err := c.FormFile("image")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "No file uploaded"})
		return
	}

	contentType := file.Header.Get("Content-Type")

	url, err := h.storage.UploadRestaurantImage(c.Request.Context(), restaurantID, file, contentType)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to upload"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"url": url,
	})
}
```

## Environment Variables

Add to `.env` files:

```bash
# AWS Configuration
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
S3_BUCKET=cravex-storage
S3_BUCKET_URL=https://cravex-storage.s3.amazonaws.com
```

## Security Best Practices

1. **IAM Roles**: Use IAM roles instead of access keys in production
2. **Bucket Policies**: Restrict access with bucket policies
3. **Encryption**: Enable server-side encryption for all uploads
4. **Versioning**: Enable versioning to recover from accidental deletions
5. **Lifecycle Policies**: Set up automatic cleanup of old files
6. **Private Buckets**: Keep buckets private and use presigned URLs
7. **CORS**: Configure CORS for frontend access

### Bucket Policy Example

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowSSLRequestsOnly",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::cravex-storage",
        "arn:aws:s3:::cravex-storage/*"
      ],
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
```

## Monitoring

### AWS CloudWatch

Set up CloudWatch metrics for:
- Bucket size (Bytes)
- Number of objects
- PUT/GET/DELETE requests
- 4xx/5xx error rates
- Data transfer

### S3 Access Logs

Enable access logging:

```bash
aws s3api put-bucket-logging \
  --bucket cravex-storage \
  --bucket-logging-status \
  '{"LoggingEnabled":{"TargetBucket":"cravex-logs","TargetPrefix":"s3-access-logs/"}}'
```

## Cost Optimization

1. **Storage Classes**: Use appropriate storage classes
   - Standard: Frequently accessed files
   - Standard IA: Infrequently accessed files
   - Glacier: Long-term archival

2. **Lifecycle Policies**: Automatically transition old files
3. **Compression**: Compress files before upload
4. **CDN**: Use CloudFront for global distribution
5. **Monitoring**: Set up cost alerts

## Troubleshooting

### Access Denied

```bash
# Check IAM permissions
aws iam get-user-policy --name S3Access --user-name cravex-user

# Check bucket policy
aws s3api get-bucket-policy --bucket cravex-storage
```

### Upload Failures

```bash
# Check bucket exists
aws s3 ls s3://cravex-storage

# Check credentials
aws sts get-caller-identity

# Test upload
aws s3 cp test.txt s3://cravex-storage/test.txt
```

### Performance Issues

```bash
# Check bucket size
aws s3 ls s3://cravex-storage --recursive --human-readable --summarize

# Check multipart uploads
aws s3api list-multipart-uploads --bucket cravex-storage
```

## Production Considerations

1. **Multi-Region**: Use S3 Cross-Region Replication for disaster recovery
2. **CDN Integration**: Use CloudFront for global content delivery
3. **Backup Strategy**: Regular backups to Glacier
4. **Monitoring**: Set up CloudWatch alarms
5. **Cost Management**: Use budget alerts and cost optimization
6. **Security**: Enable MFA for bucket deletion
7. **Compliance**: Enable compliance features for regulated industries

## Next Steps

- [ ] Set up CloudFront CDN for global distribution
- [ ] Implement image optimization (compression, resizing)
- [ ] Add S3 event notifications for Lambda triggers
- [ ] Set up automated backup to Glacier
- [ ] Implement S3 Select for querying data
- [ ] Add integration tests for S3 operations
- [ ] Set up cost monitoring and alerts
