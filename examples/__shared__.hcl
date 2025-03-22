remote_state {
    backend ="s3"
    
    generate = {
        path = "backend.tf"
        if_exists = "overwrite_terragrunt"
    }

    config = {
        bucket = "dk-state-bucket"
        key = "${path_relative_to_include()}/terraform.tfstate"
        region = "ap-northeast-2"
        profile = "leedonggyu"

        encrypt = false
        skip_bucket_root_access=true
        enable_lock_table_ssencryption = false
        skip_bucket_enforced_tls = true
        skip_bucket_ssencryption = true
    }
}

generate "provider" {
    path = "provider.tf"
    if_exists = "overwrite_terragrunt"

    contents = <<EOF
    provider "aws" {
        region = "ap-northeast-2"
        profile = "leedonggyu"
    }
    EOF
}

    