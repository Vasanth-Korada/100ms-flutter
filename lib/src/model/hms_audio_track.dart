// Project imports:
import 'package:hmssdk_flutter/hmssdk_flutter.dart';

///parent of all audio tracks
class HMSAudioTrack extends HMSTrack {
  HMSAudioTrack(
      {required HMSTrackKind kind,
      required String source,
      required String trackId,
      required String trackDescription,
      required bool isMute,
      HMSPeer? peer})
      : super(
            kind: kind,
            source: source,
            trackDescription: trackDescription,
            trackId: trackId,
            isMute: isMute,
            peer: peer);

  ///returns true if audio is mute
  factory HMSAudioTrack.fromMap({required Map map, HMSPeer? peer}) {
    if (peer == null)
      return HMSAudioTrack(
          trackId: map['track_id'],
          trackDescription: map['track_description'],
          source: map['track_source'],
          kind: HMSTrackKindValue.getHMSTrackKindFromName(map['track_kind']),
          isMute: map['track_mute'],
          peer: peer);

    if (!peer.isLocal) {
      return HMSRemoteAudioTrack.fromMap(map: map, peer: peer);
    }

    return HMSLocalAudioTrack.fromMap(map: map, peer: peer);
  }
}
