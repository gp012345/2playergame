// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_score.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GameScoreAdapter extends TypeAdapter<GameScore> {
  @override
  final int typeId = 0;

  @override
  GameScore read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GameScore(
      gameType: fields[0] as String,
      player1Score: fields[1] as int,
      player2Score: fields[2] as int,
      winner: fields[4] as int,
      gameDuration: fields[5] as int? ?? 0,
      gameData: fields[6] as String?,
      timestamp: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, GameScore obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.gameType)
      ..writeByte(1)
      ..write(obj.player1Score)
      ..writeByte(2)
      ..write(obj.player2Score)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.winner)
      ..writeByte(5)
      ..write(obj.gameDuration)
      ..writeByte(6)
      ..write(obj.gameData);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is GameScoreAdapter &&
              runtimeType == other.runtimeType &&
              typeId == other.typeId;
}