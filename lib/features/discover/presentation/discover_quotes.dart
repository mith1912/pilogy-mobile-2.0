/// Editorial reflections only; these are never numerical interpretations.
const discoverQuotes = <String>[
  'Sự tĩnh lặng mở ra khoảng trống để bạn lắng nghe chính mình.',
  'Mỗi bước nhỏ cũng là một cách chăm sóc hành trình của bạn.',
  'Bạn có thể chậm lại mà vẫn đang tiến về phía trước.',
  'Hiểu mình bắt đầu từ một lần lắng nghe không phán xét.',
  'Hãy dành cho bản thân sự dịu dàng bạn thường trao cho người khác.',
  'Một ngày bình thường cũng có những điều đáng trân trọng.',
  'Không cần mọi câu trả lời để bắt đầu một bước chân.',
  'Sự rõ ràng đôi khi đến sau một khoảng nghỉ.',
  'Điều bạn học hôm nay có thể mở thêm một góc nhìn ngày mai.',
  'Bạn được phép thay đổi khi hiểu thêm về chính mình.',
  'Một lời cảm ơn nhỏ có thể làm ngày hôm nay ấm hơn.',
  'Lắng nghe cảm xúc là một cách trở về với hiện tại.',
  'Có những điều chỉ trở nên rõ nét khi ta thôi vội vàng.',
  'Hãy để sự tò mò dẫn bạn đến một điều mới mẻ.',
  'Chăm sóc những điều nhỏ là cách nuôi dưỡng sự bình yên.',
  'Bạn không cần giống ai để trân trọng giá trị của mình.',
  'Một nhịp thở sâu cũng có thể là khởi đầu của sự cân bằng.',
  'Mỗi trải nghiệm là một lời mời để nhìn mình bằng đôi mắt mới.',
  'Sự kiên nhẫn cho bạn thêm không gian để trưởng thành.',
  'Hôm nay, hãy dành một khoảnh khắc cho điều thật sự có ý nghĩa.',
];

/// Matches the prototype's Nguyễn Minh Anh → Minh Anh greeting without
/// modifying the canonical profile input sent to the backend.
String discoverGreetingName(String fullName) {
  final parts = fullName.trim().split(RegExp(r'\s+'));
  return parts.length >= 3
      ? parts.sublist(parts.length - 2).join(' ')
      : parts.last;
}
