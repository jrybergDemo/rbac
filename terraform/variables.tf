variable "managed_id_role_assignments" {
  description = "Map of managed identity role assignments."
  default     = {}
  type        = map(list(object({
    object_id   = string
    role_name   = string
    role_type   = string
    scope       = string
  })))
}

variable "group_role_assignments" {
  description = "Map of group role assignments."
  default     = {}
  type        = map(list(object({
    role_name   = string
    role_type   = string
    scope       = string
  })))
}

variable "sp_role_assignments" {
  description = "Map of service principal role assignments."
  default     = {}
  type        = map(list(object({
    role_name   = string
    role_type   = string
    scope       = string
  })))
}

variable "user_role_assignments" {
  description = "Map of user role assignments."
  default     = {}
  type        = map(list(object({
    role_name   = string
    role_type   = string
    scope       = string
  })))
}
