terraform{
    required_providers{
        azurerm = {
            source = "hashicorp/azurerm"
            version = "=2.46.0"
        }
    }

    backend "local" {
        path = "terraform.tfstate"
  }
}

provider "azurerm"{
    features{}
    subscription_id = "3f311599-d73b-43a4-8dbf-dee2082100f6"
    # client_id       = "dc39e21c-9d6b-4efa-8a45-db7e65149a03"
    # client_secret   = "ed6d001d-38c2-4b09-8f92-d1285d3326b4"
    tenant_id       = "e342d848-a6cb-46aa-ac19-4800f62fb836"
}