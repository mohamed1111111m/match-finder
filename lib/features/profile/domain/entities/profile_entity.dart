// Profile domain entity reuses UserEntity — expose it with a type alias
// so profile feature stays decoupled from auth feature details.

export '../../../auth/domain/entities/user_entity.dart' show UserEntity;
