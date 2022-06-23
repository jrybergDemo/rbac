data "azurerm_subscription" "current" {}

locals {
  subscription_name = data.azurerm_subscription.current.display_name
  subscription_id = data.azurerm_subscription.current.id
  custom_roles = {
    for role_key, role_value in jsondecode(file("${path.module}/custom_roles.json")) :
    "${local.subscription_name} - ${role_key}" => {
      description         = "${role_value.description}"
      permissions         = "${role_value.permissions}"
      role_reference_name = role_key
    }
  }
}

resource "random_uuid" "role_definition" {
  for_each = local.custom_roles
}

resource "azurerm_role_definition" "custom" {
  for_each           = local.custom_roles
  name               = each.key
  description        = each.value.description
  scope              = local.subscription_id
  role_definition_id = random_uuid.role_definition[each.key].id
  assignable_scopes  = [local.subscription_id]

  permissions {
    actions     = each.value.permissions.actions
    not_actions = lookup(each.value, "not_actions", null)
  }
}

data "azuread_group" "groups" {
  for_each     = var.group_role_assignments
  display_name = each.key
}

data "azuread_service_principal" "sp" {
  for_each     = var.sp_role_assignments
  display_name = each.key
}

data "azuread_user" "users" {
  for_each            = var.user_role_assignments
  user_principal_name = each.key
}

locals {
  principals = merge(
    data.azuread_group.groups,
    data.azuread_service_principal.sp,
    data.azuread_user.users
  )
  assignments = merge(
    var.group_role_assignments,
    var.sp_role_assignments,
    var.user_role_assignments,
    var.managed_id_role_assignments
  )
  role_assignments = flatten([
    for assignment_principal, assignment_list in local.assignments : [
      for assignment_object in assignment_list : {
        assignment_key = "${assignment_principal} - ${assignment_object.role_name} - ${join("/", reverse(chunklist(reverse(split("/", assignment_object.scope)), 2)[0]))}"
        principal_id   = can(assignment_object.object_id) ? assignment_object.object_id : local.principals[assignment_principal].object_id
        role_name      = assignment_object.role_type != "custom" ? assignment_object.role_name : "${local.subscription_name} - ${assignment_object.role_name}"
        scope          = assignment_object.scope
      }
    ]
  ])
}

resource "azurerm_role_assignment" "assign" {
  for_each = {
    for assignment_object in local.role_assignments :
    assignment_object.assignment_key => assignment_object
  }

  principal_id         = each.value.principal_id
  role_definition_name = each.value.role_name
  scope                = each.value.scope
  depends_on           = [azurerm_role_definition.custom]
}
