/// Forum topic labels (aligned with RN `constants/forumLabels.ts`).
abstract final class ForumLabels {
  static const all = <String>[
    'ky-thuat-trong',
    'phan-bon',
    'sau-benh',
    'tuoi-nuoc',
    'thu-hoach',
    'bao-quan',
    'thi-truong',
    'khac',
  ];

  static const display = <String, String>{
    'ky-thuat-trong': 'Kỹ thuật trồng',
    'phan-bon': 'Phân bón',
    'sau-benh': 'Sâu bệnh',
    'tuoi-nuoc': 'Tưới nước',
    'thu-hoach': 'Thu hoạch',
    'bao-quan': 'Bảo quản',
    'thi-truong': 'Thị trường',
    'khac': 'Khác',
  };

  static String labelOf(String slug) => display[slug] ?? slug;
}
