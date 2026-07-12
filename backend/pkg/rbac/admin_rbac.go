package rbac

import (
	"context"
	"fmt"

	"github.com/google/uuid"
)

// RBACService implements Role-Based Access Control for admin dashboard
// - City managers shouldn't see other cities' finance data
// - Support staff shouldn't approve payouts
// - Role-based permissions with hierarchical inheritance
type RBACService struct {
	roleRepo RoleRepository
}

type RoleRepository interface {
	GetUserRoles(ctx context.Context, userID uuid.UUID) ([]*Role, error)
	GetRolePermissions(ctx context.Context, roleID uuid.UUID) ([]*Permission, error)
	GetUserCities(ctx context.Context, userID uuid.UUID) ([]string, error)
}

type Role struct {
	ID          uuid.UUID
	Name        string
	Description string
	ParentRole  *uuid.UUID // For role hierarchy
}

type Permission struct {
	ID          uuid.UUID
	Resource    string // e.g., "orders", "finance", "restaurants"
	Action      string // e.g., "read", "write", "delete", "approve"
	Scope       string // e.g., "all", "city", "own"
}

type AccessCheck struct {
	UserID      uuid.UUID
	Resource    string
	Action      string
	ResourceID  string // Optional: specific resource ID
	CityID      string // Optional: city-specific access
}

type AccessResult struct {
	Allowed bool
	Reason  string
}

func NewRBACService(roleRepo RoleRepository) *RBACService {
	return &RBACService{
		roleRepo: roleRepo,
	}
}

// CheckAccess checks if a user has permission to perform an action on a resource
func (rbac *RBACService) CheckAccess(ctx context.Context, check *AccessCheck) (*AccessResult, error) {
	// Get user's roles
	roles, err := rbac.roleRepo.GetUserRoles(ctx, check.UserID)
	if err != nil {
		return &AccessResult{Allowed: false, Reason: "failed to get roles"}, nil
	}

	if len(roles) == 0 {
		return &AccessResult{Allowed: false, Reason: "no roles assigned"}, nil
	}

	// Check each role for permission
	for _, role := range roles {
		// Get permissions for this role
		permissions, err := rbac.roleRepo.GetRolePermissions(ctx, role.ID)
		if err != nil {
			continue
		}

		// Check if any permission grants access
		for _, perm := range permissions {
			if rbac.permissionMatches(perm, check) {
				// Check city-specific access if required
				if check.CityID != "" && perm.Scope == "city" {
					userCities, err := rbac.roleRepo.GetUserCities(ctx, check.UserID)
					if err != nil {
						continue
					}

					hasCityAccess := false
					for _, cityID := range userCities {
						if cityID == check.CityID {
							hasCityAccess = true
							break
						}
					}

					if !hasCityAccess {
						return &AccessResult{Allowed: false, Reason: "no access to this city"}, nil
					}
				}

				return &AccessResult{Allowed: true, Reason: "permission granted"}, nil
			}
		}
	}

	return &AccessResult{Allowed: false, Reason: "insufficient permissions"}, nil
}

// permissionMatches checks if a permission matches the access check
func (rbac *RBACService) permissionMatches(permission *Permission, check *AccessCheck) bool {
	// Check resource match
	if permission.Resource != "*" && permission.Resource != check.Resource {
		return false
	}

	// Check action match
	if permission.Action != "*" && permission.Action != check.Action {
		return false
	}

	return true
}

// HasAnyRole checks if user has any of the specified roles
func (rbac *RBACService) HasAnyRole(ctx context.Context, userID uuid.UUID, roleNames []string) (bool, error) {
	roles, err := rbac.roleRepo.GetUserRoles(ctx, userID)
	if err != nil {
		return false, err
	}

	for _, role := range roles {
		for _, roleName := range roleNames {
			if role.Name == roleName {
				return true, nil
			}
		}
	}

	return false, nil
}

// GetEffectivePermissions returns all effective permissions for a user (including inherited)
func (rbac *RBACService) GetEffectivePermissions(ctx context.Context, userID uuid.UUID) ([]*Permission, error) {
	roles, err := rbac.roleRepo.GetUserRoles(ctx, userID)
	if err != nil {
		return nil, err
	}

	permissionMap := make(map[string]*Permission)

	for _, role := range roles {
		permissions, err := rbac.roleRepo.GetRolePermissions(ctx, role.ID)
		if err != nil {
			continue
		}

		for _, perm := range permissions {
			key := fmt.Sprintf("%s:%s", perm.Resource, perm.Action)
			permissionMap[key] = perm
		}
	}

	permissions := make([]*Permission, 0, len(permissionMap))
	for _, perm := range permissionMap {
		permissions = append(permissions, perm)
	}

	return permissions, nil
}

// Predefined roles for the system
const (
	RoleSuperAdmin = "super_admin"
	RoleCityManager = "city_manager"
	RoleFinanceManager = "finance_manager"
	RoleSupportStaff = "support_staff"
	RoleRestaurantManager = "restaurant_manager"
	RoleRiderManager = "rider_manager"
)

// GetDefaultRoles returns default role definitions
func GetDefaultRoles() []*Role {
	return []*Role{
		{
			Name:        RoleSuperAdmin,
			Description: "Full access to all resources across all cities",
		},
		{
			Name:        RoleCityManager,
			Description: "Manage restaurants, riders, and operations within assigned city",
		},
		{
			Name:        RoleFinanceManager,
			Description: "View and manage financial data within assigned cities",
		},
		{
			Name:        RoleSupportStaff,
			Description: "View orders and customer data, limited write access",
		},
		{
			Name:        RoleRestaurantManager,
			Description: "Manage restaurant menu and operations",
		},
		{
			Name:        RoleRiderManager,
			Description: "Manage rider assignments and payouts",
		},
	}
}

// GetDefaultPermissions returns default permission definitions
func GetDefaultPermissions() []*Permission {
	return []*Permission{
		// Super admin permissions
		{Resource: "*", Action: "*", Scope: "all"},
		
		// City manager permissions
		{Resource: "restaurants", Action: "read", Scope: "city"},
		{Resource: "restaurants", Action: "write", Scope: "city"},
		{Resource: "riders", Action: "read", Scope: "city"},
		{Resource: "riders", Action: "write", Scope: "city"},
		{Resource: "orders", Action: "read", Scope: "city"},
		{Resource: "orders", Action: "write", Scope: "city"},
		
		// Finance manager permissions
		{Resource: "finance", Action: "read", Scope: "city"},
		{Resource: "finance", Action: "write", Scope: "city"},
		{Resource: "payouts", Action: "read", Scope: "city"},
		{Resource: "payouts", Action: "approve", Scope: "city"},
		
		// Support staff permissions
		{Resource: "orders", Action: "read", Scope: "all"},
		{Resource: "users", Action: "read", Scope: "all"},
		{Resource: "restaurants", Action: "read", Scope: "all"},
		
		// Restaurant manager permissions
		{Resource: "restaurants", Action: "read", Scope: "own"},
		{Resource: "restaurants", Action: "write", Scope: "own"},
		{Resource: "menu", Action: "read", Scope: "own"},
		{Resource: "menu", Action: "write", Scope: "own"},
		
		// Rider manager permissions
		{Resource: "riders", Action: "read", Scope: "all"},
		{Resource: "riders", Action: "write", Scope: "all"},
		{Resource: "payouts", Action: "read", Scope: "all"},
	}
}

// AssignRole assigns a role to a user (admin function)
func (rbac *RBACService) AssignRole(ctx context.Context, userID, roleID uuid.UUID) error {
	// In production, this would update the database
	return nil
}

// RevokeRole revokes a role from a user (admin function)
func (rbac *RBACService) RevokeRole(ctx context.Context, userID, roleID uuid.UUID) error {
	// In production, this would update the database
	return nil
}

// AssignCityToUser assigns a city to a user for city-specific access
func (rbac *RBACService) AssignCityToUser(ctx context.Context, userID uuid.UUID, cityID string) error {
	// In production, this would update the database
	return nil
}

// RevokeCityFromUser revokes city access from a user
func (rbac *RBACService) RevokeCityFromUser(ctx context.Context, userID uuid.UUID, cityID string) error {
	// In production, this would update the database
	return nil
}

// RBACMiddleware provides middleware for checking permissions
type RBACMiddleware struct {
	rbacService *RBACService
}

func NewRBACMiddleware(rbacService *RBACService) *RBACMiddleware {
	return &RBACMiddleware{
		rbacService: rbacService,
	}
}

// RequirePermission middleware checks if user has required permission
func (rm *RBACMiddleware) RequirePermission(resource, action string) func(context.Context, uuid.UUID) error {
	return func(ctx context.Context, userID uuid.UUID) error {
		check := &AccessCheck{
			UserID:   userID,
			Resource: resource,
			Action:   action,
		}

		result, err := rm.rbacService.CheckAccess(ctx, check)
		if err != nil {
			return fmt.Errorf("failed to check access: %w", err)
		}

		if !result.Allowed {
			return fmt.Errorf("access denied: %s", result.Reason)
		}

		return nil
	}
}

// RequireRole middleware checks if user has required role
func (rm *RBACMiddleware) RequireRole(roleName string) func(context.Context, uuid.UUID) error {
	return func(ctx context.Context, userID uuid.UUID) error {
		hasRole, err := rm.rbacService.HasAnyRole(ctx, userID, []string{roleName})
	if err != nil {
		return fmt.Errorf("failed to check role: %w", err)
	}

	if !hasRole {
		return fmt.Errorf("access denied: required role %s", roleName)
	}

	return nil
	}
}
