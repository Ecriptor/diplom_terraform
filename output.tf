//приватный ip
output "private_ip" {
 value = aws_instance.diplom-vm.*.private_ip
}
//публичный ip
output "public_ip" {
 value = aws_instance.diplom-vm.*.public_ip
}