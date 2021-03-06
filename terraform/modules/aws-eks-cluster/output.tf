output "eks" {
  value = module.eks
}

output "policy" {
  value = aws_iam_policy.worker-policy
}

output "sg" {
  value = aws_security_group.all_worker_mgmt
}
