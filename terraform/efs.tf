
resource "aws_efs_access_point" "file-system-access-point" {
  file_system_id = aws_efs_file_system.file-system.id

  posix_user {
    gid = local.efs_gid
    uid = local.efs_uid
  }

  root_directory {
    creation_info {
      owner_gid   = local.efs_gid
      owner_uid   = local.efs_uid
      permissions = "0755"
    }

    path = "/minecraft"
  }

  tags = {
    Name = "${var.name}-mc-on-demand-access-point"
  }
}

resource "aws_efs_file_system" "file-system" {
  encrypted = true

  // @TODO: Add a variable for this
  #  lifecycle {
  #    prevent_destroy = true
  #  }

  tags = {
    Name = "${var.name}-mc-on-demand-file-system"
  }
}

resource "aws_efs_mount_target" "file-system-mount-target" {
  count           = length(module.vpc.isolated_subnet_ids)
  file_system_id  = aws_efs_file_system.file-system.id
  security_groups = [aws_security_group.file-system-security-group.id]
  subnet_id       = module.vpc.isolated_subnet_ids[count.index]
}