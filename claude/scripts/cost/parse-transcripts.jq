select(type == "object") |
select(.type == "assistant" and .message.usage != null) |
select(.timestamp != null) |
. as $msg |
($msg.timestamp | sub("\\.\\d+Z$"; "Z") | fromdateiso8601) as $ts |
select($ts >= $cutoff) |
{
  date: ($ts | strftime("%Y-%m-%d")),
  model: $msg.message.model,
  usage: $msg.message.usage
}
