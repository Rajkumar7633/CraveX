package storage

import (
	"context"
	"fmt"
	"mime/multipart"
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

func (s *StorageService) UploadRestaurantImage(ctx context.Context, restaurantID string, file multipart.File, contentType string) (string, error) {
	ext := strings.Split(contentType, "/")[1]
	key := fmt.Sprintf("restaurants/%s/%s.%s", restaurantID, uuid.New().String(), ext)
	return s.s3.UploadFile(ctx, key, file, contentType)
}

func (s *StorageService) UploadUserAvatar(ctx context.Context, userID string, file multipart.File, contentType string) (string, error) {
	ext := strings.Split(contentType, "/")[1]
	key := fmt.Sprintf("users/%s/avatar.%s", userID, ext)
	return s.s3.UploadFile(ctx, key, file, contentType)
}

func (s *StorageService) UploadRiderDocument(ctx context.Context, riderID, docType string, file multipart.File, contentType string) (string, error) {
	ext := strings.Split(contentType, "/")[1]
	key := fmt.Sprintf("riders/%s/%s/%s.%s", riderID, docType, uuid.New().String(), ext)
	return s.s3.UploadFile(ctx, key, file, contentType)
}

func (s *StorageService) UploadMenuItemImage(ctx context.Context, restaurantID, menuItemID string, file multipart.File, contentType string) (string, error) {
	ext := strings.Split(contentType, "/")[1]
	key := fmt.Sprintf("menu/%s/%s/%s.%s", restaurantID, menuItemID, uuid.New().String(), ext)
	return s.s3.UploadFile(ctx, key, file, contentType)
}

func (s *StorageService) UploadReport(ctx context.Context, reportType, date string, data []byte) (string, error) {
	key := fmt.Sprintf("reports/%s/%s-%s.csv", reportType, date, uuid.New().String())
	return s.s3.UploadBytes(ctx, key, data, "text/csv")
}

func (s *StorageService) DeleteRestaurantImage(ctx context.Context, key string) error {
	return s.s3.DeleteFile(ctx, key)
}

func (s *StorageService) GetRestaurantImageURL(ctx context.Context, key string) (string, error) {
	return s.s3.GetPresignedURL(ctx, key, 24*time.Hour)
}

func (s *StorageService) ListRestaurantImages(ctx context.Context, restaurantID string) ([]string, error) {
	prefix := fmt.Sprintf("restaurants/%s/", restaurantID)
	return s.s3.ListFiles(ctx, prefix)
}
