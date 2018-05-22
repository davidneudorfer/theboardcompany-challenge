//
// Base
//

aws_region = "us-west-2"

environment = "dev"

key_pair = "theboardcompany"

base_domain = "tbc.vasandani.me"

//
// App
//

app_spot_price = "0.007"

app_instance_size = "m3.medium"

app_subdomain = "challenge"

app_service_count = 1

app_instance_count = 1

app_root_volume_size = 10

app_image = "tutum/hello-world:latest"
