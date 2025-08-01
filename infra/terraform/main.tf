# ECS Task Definition for Payment
resource "aws_ecs_task_definition" "payment" {
  family                   = "payment"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode([
    {
      name      = "payment"
      image     = var.payment_image_uri
      portMappings = [{
        containerPort = 5000
        hostPort      = 5000
      }]
      environment = []
    }
  ])
}

# ECS Task Definition for User
resource "aws_ecs_task_definition" "user" {
  family                   = "user"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode([
    {
      name      = "user"
      image     = var.user_image_uri
      portMappings = [{
        containerPort = 5000
        hostPort      = 5000
      }]
      environment = []
    }
  ])
}

# ECS Task Definition for Frontend
resource "aws_ecs_task_definition" "frontend" {
  family                   = "frontend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode([
    {
      name      = "frontend"
      image     = var.frontend_image_uri
      portMappings = [{
        containerPort = 80
        hostPort      = 80
      }]
      environment = []
    }
  ])
}
provider "aws" {
  region = var.aws_region
}

terraform {
  backend "s3" {
    bucket = "travelease-terraform-state"
    key    = "state/terraform.tfstate"
    region = var.aws_region
  }
}

resource "aws_ecr_repository" "booking" {
  name = "travelease-booking"
}
resource "aws_ecr_repository" "payment" {
  name = "travelease-payment"
}
resource "aws_ecr_repository" "user" {
  name = "travelease-user"
}
resource "aws_ecr_repository" "frontend" {
  name = "travelease-frontend"
}


# Networking (VPC, Subnets, Security Groups)
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true
}

resource "aws_security_group" "alb" {
  vpc_id = aws_vpc.main.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Application Load Balancer
resource "aws_lb" "app" {
  name               = "travelease-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

resource "aws_lb_target_group" "booking" {
  name     = "booking-tg"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check {
    path = "/health"
  }
}

resource "aws_lb_target_group" "payment" {
  name     = "payment-tg"
  port     = 5001
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check {
    path = "/health"
  }
}

resource "aws_lb_target_group" "user" {
  name     = "user-tg"
  port     = 5002
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check {
    path = "/health"
  }
}

resource "aws_lb_target_group" "frontend" {
  name     = "frontend-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check {
    path = "/"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

resource "aws_lb_listener_rule" "booking" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.booking.arn
  }
  condition {
    path_pattern {
      values = ["/booking*"]
    }
  }
}

resource "aws_lb_listener_rule" "payment" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 20
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.payment.arn
  }
  condition {
    path_pattern {
      values = ["/payment*"]
    }
  }
}

resource "aws_lb_listener_rule" "user" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 30
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.user.arn
  }
  condition {
    path_pattern {
      values = ["/user*"]
    }
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "travelease" {
  name = "travelease-cluster"
}

# ECS Task Execution Role
data "aws_iam_policy_document" "ecs_task_execution_role_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_role_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Task Definitions
resource "aws_ecs_task_definition" "booking" {
  family                   = "booking"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode([
    {
      name      = "booking"
      image     = var.booking_image_uri
      portMappings = [{
        containerPort = 5000
        hostPort      = 5000
      }]
      environment = [
        { name = "API_KEY" value = var.api_key }
      ]
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:5000/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 10
      }
    }
  ])
}

resource "aws_ecs_task_definition" "payment" {
  family                   = "payment"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode([
    {
      name      = "payment"
      image     = var.payment_image_uri
      portMappings = [{
        containerPort = 5001
        hostPort      = 5001
      }]
      environment = [
        { name = "API_KEY" value = var.api_key }
      ]
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:5001/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 10
      }
    }
  ])
}

resource "aws_ecs_task_definition" "user" {
  family                   = "user"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode([
    {
      name      = "user"
      image     = var.user_image_uri
      portMappings = [{
        containerPort = 5002
        hostPort      = 5002
      }]
      environment = [
        { name = "API_KEY" value = var.api_key }
      ]
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:5002/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 10
      }
    }
  ])
}

resource "aws_ecs_task_definition" "frontend" {
  family                   = "frontend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode([
    {
      name      = "frontend"
      image     = var.frontend_image_uri
      portMappings = [{
        containerPort = 80
        hostPort      = 80
      }]
      environment = []
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:80 || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 10
      }
    }
  ])
}

# ECS Services
resource "aws_ecs_service" "booking" {
  name            = "booking"
  cluster         = aws_ecs_cluster.travelease.id
  task_definition = aws_ecs_task_definition.booking.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = [aws_subnet.public_a.id, aws_subnet.public_b.id]
    security_groups  = [aws_security_group.alb.id]
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.booking.arn
    container_name   = "booking"
    container_port   = 5000
  }
  depends_on = [aws_lb_listener.http]
}

resource "aws_ecs_service" "payment" {
  name            = "payment"
  cluster         = aws_ecs_cluster.travelease.id
  task_definition = aws_ecs_task_definition.payment.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = [aws_subnet.public_a.id, aws_subnet.public_b.id]
    security_groups  = [aws_security_group.alb.id]
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.payment.arn
    container_name   = "payment"
    container_port   = 5001
  }
  depends_on = [aws_lb_listener.http]
}

resource "aws_ecs_service" "user" {
  name            = "user"
  cluster         = aws_ecs_cluster.travelease.id
  task_definition = aws_ecs_task_definition.user.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = [aws_subnet.public_a.id, aws_subnet.public_b.id]
    security_groups  = [aws_security_group.alb.id]
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.user.arn
    container_name   = "user"
    container_port   = 5002
  }
  depends_on = [aws_lb_listener.http]
}

resource "aws_ecs_service" "frontend" {
  name            = "frontend"
  cluster         = aws_ecs_cluster.travelease.id
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = [aws_subnet.public_a.id, aws_subnet.public_b.id]
    security_groups  = [aws_security_group.alb.id]
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.frontend.arn
    container_name   = "frontend"
    container_port   = 80
  }
  depends_on = [aws_lb_listener.http]
}
