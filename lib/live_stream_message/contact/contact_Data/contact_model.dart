//模型层
class ContactModel {
  final String id;
  final String title; //标题
  final String iconUrl; //头像
  final String bgUrl; //背景
  final String? remark; //备注名
  final String? tag; //标签(如：A, B, C 或 "朋友", "同事")
  ContactModel({
    required this.id,
    required this.title,
    required this.iconUrl,
    this.remark,
    this.tag,
    this.bgUrl = 'assets/image/005.jpeg', //默认背景
  });
  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '未知用户', //
      iconUrl: json['icon']?.toString() ?? '',
      bgUrl: json['bgUrl']?.toString() ?? 'assets/image/010.jpeg',//活的数据
      remark: json['remark'],
      tag: json['tag'],
    );
  }
}
