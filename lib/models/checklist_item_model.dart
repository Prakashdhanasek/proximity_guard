class ChecklistItemModel {
  final String id;
  final String title;
  final String description;
  final bool isCompleted;

  ChecklistItemModel({
    required this.id,
    required this.title,
    this.description = '',
    this.isCompleted = false,
  });

  ChecklistItemModel copyWith({bool? isCompleted}) {
    return ChecklistItemModel(
      id: id,
      title: title,
      description: description,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
