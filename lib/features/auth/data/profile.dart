enum UserRole { manajemen, guru, orangTua }

UserRole roleFromDb(String value) => switch (value) {
  'manajemen' => UserRole.manajemen,
  'guru' => UserRole.guru,
  _ => UserRole.orangTua,
};

extension UserRoleLabel on UserRole {
  String get label => switch (this) {
    UserRole.manajemen => 'Pihak Sekolah',
    UserRole.guru => 'Guru',
    UserRole.orangTua => 'Orang Tua',
  };
}

class Profile {
  final String id;
  final String namaLengkap;
  final String email;
  final String? noWhatsapp;
  final String? nip;
  final String? fotoUrl;
  final UserRole role;
  final bool isActive;

  const Profile({
    required this.id,
    required this.namaLengkap,
    required this.email,
    required this.role,
    required this.isActive,
    this.noWhatsapp,
    this.nip,
    this.fotoUrl,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    id: json['id'] as String,
    namaLengkap: json['nama_lengkap'] as String,
    email: json['email'] as String,
    noWhatsapp: json['no_whatsapp'] as String?,
    nip: json['nip'] as String?,
    fotoUrl: json['foto_url'] as String?,
    role: roleFromDb(json['role'] as String),
    isActive: json['is_active'] as bool? ?? true,
  );
}
