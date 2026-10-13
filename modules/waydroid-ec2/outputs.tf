output "instance_id" {
  value = aws_instance.waydroid.id
}

output "connect" {
  value = "adb connect waydroid:5555 && scrcpy -s waydroid:5555 --no-audio --video-encoder=c2.android.avc.encoder --max-size 1280"
}

output "manual_start" {
  value = "aws ec2 start-instances --instance-ids ${aws_instance.waydroid.id} --region ${data.aws_region.current.region}"
}

output "manual_stop" {
  value = "aws ec2 stop-instances --instance-ids ${aws_instance.waydroid.id} --region ${data.aws_region.current.region}"
}
