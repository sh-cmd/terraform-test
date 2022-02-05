data mongodbatlas_clusters this {
  project_id = var.mongdbatlas_project_id
}

data mongodbatlas_cluster this {
  for_each = toset(data.mongodbatlas_clusters.this.results[*].name)

  project_id = var.mongdbatlas_project_id
  name       = each.value

  connection_strings = {
     for svc in var.service_configuration : connection_strings => "mongodb+srv://${svc.serviceName}:${random_password.store-service-password}@${svc.mongoCluster}/${svc.mongoDatabase}/${svc.mongoCollection}"
  }
}

resource random_password store-service-password {
  # Generate a unique new password for the DB user
  length           = 16
  special          = true
  override_special = "_%@"
}

resource mongodbatlas_database_user store-service-user {
  # create a username for the service (e.g. the service name)
  username           = "${var.environment}-${each.key}" 
  # create a password for the service 
  password           = random_password.store-service-password
  # Create the right role (read only permissions) for this user and service
  dynamic roles {
    for_each = each.value.mongoCollection[*]
    content {
      role_name       = "read"
      database_name   = each.value.mongoDatabase
      collection_name = roles.value
    }
  }
}