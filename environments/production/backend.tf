terraform {
  required_version = "1.10.4"

  # In a proper multi-user/multi-team environment, you would use a remote state.
  # But for the purposes of this sample code, we will use a local state.
  backend "local" {
    path = "terraform.tfstate"
  }
}
