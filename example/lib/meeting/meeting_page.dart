import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:hmssdk_flutter/hmssdk_flutter.dart';
import 'package:hmssdk_flutter_example/common/ui/organisms/change_track_options.dart';
import 'package:hmssdk_flutter_example/common/ui/organisms/chat_bottom_sheet.dart';
import 'package:hmssdk_flutter_example/common/ui/organisms/leave_or_end_meeting.dart';
import 'package:hmssdk_flutter_example/common/ui/organisms/peer_item_organism.dart';
import 'package:hmssdk_flutter_example/common/ui/organisms/role_change_request_dialog.dart';
import 'package:hmssdk_flutter_example/common/ui/organisms/track_change_request_dialog.dart';
import 'package:hmssdk_flutter_example/common/util/utility_components.dart';
import 'package:hmssdk_flutter_example/enum/meeting_flow.dart';
import 'package:hmssdk_flutter_example/main.dart';
import 'package:hmssdk_flutter_example/meeting/meeting_controller.dart';
import 'package:hmssdk_flutter_example/meeting/meeting_store.dart';
import 'package:mobx/mobx.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'meeting_participants_list.dart';

class MeetingPage extends StatefulWidget {
  final String roomId;
  final MeetingFlow flow;
  final String user;

  const MeetingPage(
      {Key? key, required this.roomId, required this.flow, required this.user})
      : super(key: key);

  @override
  _MeetingPageState createState() => _MeetingPageState();
}

class _MeetingPageState extends State<MeetingPage> with WidgetsBindingObserver {
  late MeetingStore _meetingStore;
  late ReactionDisposer _roleChangerequestDisposer, _trackChangerequestDisposer;
  late ReactionDisposer _errorDisposer;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addObserver(this);
    _scrollController = ScrollController();
    _meetingStore = MeetingStore();
    MeetingController meetingController = MeetingController(
        roomUrl: widget.roomId, flow: widget.flow, user: widget.user);
    _meetingStore.meetingController = meetingController;

    _meetingStore.trackStatus.observe((p0) {
      print("in initmeetingTrackStatus");
    }, fireImmediately: true);

    _roleChangerequestDisposer = reaction(
        (_) => _meetingStore.roleChangeRequest,
        (event) => {
              if ((event as HMSRoleChangeRequest).suggestedBy !=
                  _meetingStore.localPeer)
                showRoleChangeDialog(event)
            });
    _trackChangerequestDisposer = reaction(
        (_) => _meetingStore.hmsTrackChangeRequest,
        (event) => {showTrackChangeDialog(event)});
    _errorDisposer = reaction(
        (_) => _meetingStore.error,
        (event) => {
              UtilityComponents.showSnackBarWithString(
                  (event as HMSError).description, context)
            });
    reaction(
        (_) => _meetingStore.reconnected,
        (event) => {
              if ((event as bool) == true)
                UtilityComponents.showSnackBarWithString(
                    "reconnected", context),
              _meetingStore.reconnected = false
            });
    reaction(
        (_) => _meetingStore.reconnecting,
        (event) => {
              if ((event as bool) == true)
                UtilityComponents.showSnackBarWithString(
                    "reconnecting", context),
            });
    super.initState();
    initMeeting();
    checkButtons();
  }

  void initMeeting() async {
    bool ans = await _meetingStore.joinMeeting();
    if (!ans) {
      UtilityComponents.showSnackBarWithString("Unable to Join", context);
      Navigator.of(context).pop();
    }
    _meetingStore.startListen();
  }

  void checkButtons() async {
    _meetingStore.isVideoOn =
        !(await _meetingStore.meetingController.isVideoMute(null));
    _meetingStore.isMicOn =
        !(await _meetingStore.meetingController.isAudioMute(null));
  }

  void showRoleChangeDialog(event) async {
    event = event as HMSRoleChangeRequest;
    String answer = await showDialog(
        context: context,
        builder: (ctx) => RoleChangeDialogOrganism(roleChangeRequest: event));
    if (answer == "OK") {
      debugPrint("OK accepted");
      _meetingStore.meetingController.acceptRoleChangeRequest();
      UtilityComponents.showSnackBarWithString(
          (event as HMSError).description, context);
    }
  }

  Future<dynamic> _onBackPressed() {
    return showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: Text('Leave the Meeting?'),
              actions: [
                TextButton(
                    onPressed: () => {
                          _meetingStore.meetingController.leaveMeeting(),
                          Navigator.pop(context, true),
                          Navigator.pushReplacement(context,
                              MaterialPageRoute(builder: (ctx) => HomePage()))
                        },
                    child:
                        Text('Yes', style: TextStyle(height: 1, fontSize: 24))),
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('Cancel',
                        style: TextStyle(
                            height: 1,
                            fontSize: 24,
                            fontWeight: FontWeight.bold))),
              ],
            ));
  }

  @override
  void dispose() {
    _roleChangerequestDisposer.reaction.dispose();
    _errorDisposer.reaction.dispose();
    _trackChangerequestDisposer.reaction.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var orientation = MediaQuery.of(context).orientation;
    var size = MediaQuery.of(context).size;
    final double itemHeight = (size.height - kToolbarHeight - 24) / 2.5;
    final double itemWidth = size.width / 2;
    final aspectRatio = itemWidth / itemHeight;
    print(aspectRatio.toString() + "AspectRatio");
    return WillPopScope(
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.roomId),
          actions: [
            Observer(
              builder: (_) => IconButton(
                iconSize: 32,
                onPressed: () {
                  _meetingStore.toggleSpeaker();
                },
                icon: Icon(_meetingStore.isSpeakerOn
                    ? Icons.volume_up
                    : Icons.volume_off),
              ),
            ),
            IconButton(
              iconSize: 32,
              onPressed: () async {
                if (_meetingStore.isVideoOn) _meetingStore.toggleCamera();
              },
              icon: Icon(Icons.switch_camera),
            ),
            IconButton(
              iconSize: 32,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ParticipantsList(
                      meetingStore: _meetingStore,
                    ),
                  ),
                );
              },
              icon: Icon(CupertinoIcons.person_3_fill),
            )
          ],
        ),
        body: Center(
          child: Container(
            width: double.infinity,
            child: Observer(
              builder: (_) {
                print("rebuilding");
                if (!_meetingStore.isMeetingStarted) return SizedBox();
                if (_meetingStore.tracks.isEmpty)
                  return Center(child: Text('Waiting for other to join!'));
                List<HMSTrack> filteredList = _meetingStore.tracks;

                return PageView.builder(
                  itemBuilder: (ctx, index) {
                    return Observer(builder: (_) {
                      print("rebuilding");
                      ObservableMap<String, HMSTrackUpdate> map = _meetingStore.trackStatus;
                      if ((index < filteredList.length && filteredList[index].source != HMSTrackSource.kHMSTrackSourceScreen)) {
                        return orientation == Orientation.portrait
                            ? Column(
                                children: [
                                  Row(
                                    children: [
                                      //if (index * 4 < filteredList.length)
                                      peerItemforIndex(index * 4, filteredList,
                                          itemHeight, itemWidth, map),
                                      //if (index * 4 + 1 < filteredList.length)
                                      peerItemforIndex(
                                          index * 4 + 1,
                                          filteredList,
                                          itemHeight,
                                          itemWidth,
                                          map),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      //if (index * 4 + 2 < filteredList.length)
                                      peerItemforIndex(
                                          index * 4 + 2,
                                          filteredList,
                                          itemHeight,
                                          itemWidth,
                                          map),
                                      //if (index * 4 + 3 < filteredList.length)
                                      peerItemforIndex(
                                          index * 4 + 3,
                                          filteredList,
                                          itemHeight,
                                          itemWidth,
                                          map),
                                    ],
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  Row(
                                    children: [
                                      peerItemforIndex(index * 2, filteredList,
                                          itemHeight * 2 - 50, itemWidth, map),
                                      peerItemforIndex(
                                          index * 2 + 1,
                                          filteredList,
                                          itemHeight * 2 - 50,
                                          itemWidth,
                                          map),
                                    ],
                                  ),
                                ],
                              );
                      } else {
                        return Container(
                          child: peerItemforIndex(0, filteredList,
                              itemHeight * 2, itemWidth * 2, map),
                        );
                      }
                    });
                    print(
                        "pageIndex ${index} ${(index < filteredList.length && filteredList[index].source != HMSTrackSource.kHMSTrackSourceScreen)}");
                  },
                  itemCount: ((filteredList.length - 1) /
                              ((orientation == Orientation.portrait) ? 4 : 2))
                          .floor() +
                      1 +
                      ((filteredList[0].source !=
                              HMSTrackSource.kHMSTrackSourceScreen)
                          ? 0
                          : 1),
                );
              },
            ),
          ),
        ),
        bottomNavigationBar: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              child: Observer(builder: (context) {
                return IconButton(
                    tooltip: 'Video',
                    iconSize: 32,
                    onPressed: () {
                      _meetingStore.toggleVideo();
                    },
                    icon: Icon(_meetingStore.isVideoOn
                        ? Icons.videocam
                        : Icons.videocam_off));
              }),
            ),
            Container(
              padding: EdgeInsets.all(8),
              child: Observer(builder: (context) {
                return IconButton(
                    tooltip: 'Audio',
                    iconSize: 32,
                    onPressed: () {
                      _meetingStore.toggleAudio();
                    },
                    icon: Icon(
                        _meetingStore.isMicOn ? Icons.mic : Icons.mic_off));
              }),
            ),
            Container(
              padding: EdgeInsets.all(8),
              child: IconButton(
                  tooltip: 'Chat',
                  iconSize: 32,
                  onPressed: () {
                    chatMessages(context, _meetingStore);
                  },
                  icon: Icon(Icons.chat_bubble)),
            ),
            Container(
              padding: EdgeInsets.all(8),
              child: IconButton(
                  tooltip: 'Leave Or End',
                  iconSize: 32,
                  onPressed: () async {
                    String ans = await showDialog(
                        context: context,
                        builder: (_) => LeaveOrEndMeetingDialogOption(
                              meetingStore: _meetingStore,
                            ));
                    if (ans == 'Leave' || ans == 'End') Navigator.pop(context);
                  },
                  icon: Icon(Icons.call_end)),
            ),
          ],
        ),
      ),
      onWillPop: () async {
        bool ans = await _onBackPressed();
        return ans;
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      if (_meetingStore.isVideoOn) {
        _meetingStore.meetingController.startCapturing();
      }
    } else if (state == AppLifecycleState.paused) {
      if (_meetingStore.isVideoOn) {
        _meetingStore.meetingController.stopCapturing();
      }
    } else if (state == AppLifecycleState.inactive) {
      if (_meetingStore.isVideoOn) {
        _meetingStore.meetingController.stopCapturing();
      }
    }
  }

  showTrackChangeDialog(event) async {
    event = event as HMSTrackChangeRequest;
    String answer = await showDialog(
        context: context,
        builder: (ctx) => TrackChangeDialogOrganism(trackChangeRequest: event));
    if (answer == "OK") {
      debugPrint("OK accepted");
      _meetingStore.changeTracks();
    }
  }

  Widget peerItemforIndex(int index, List<HMSTrack> filteredList, double itemHeight, double itemWidth, Map<String, HMSTrackUpdate> map) {
    var orientation = MediaQuery.of(context).orientation;
    if (index > 0 &&
        filteredList[0].source == HMSTrackSource.kHMSTrackSourceScreen) {
      int a = index ~/ ((orientation == Orientation.portrait) ? 4 : 2);
      int b = index % ((orientation == Orientation.portrait) ? 4 : 2);

      index =
          (a - 1) * ((orientation == Orientation.portrait) ? 4 : 2) + (b + 1);
      //print("${a} a and b ${b} ${filteredList[index].peer!.name}");
    }

    if (index >= filteredList.length) return SizedBox();
    print("$index after rebuildig");
    return Observer(
      key: UniqueKey(),
      builder: (_) => InkWell(
        onLongPress: () {
          if (!filteredList[index].peer!.isLocal &&
              filteredList[index].source !=
                  HMSTrackSource.kHMSTrackSourceScreen)
            showDialog(
                context: context,
                builder: (_) => Column(
                      children: [
                        ChangeTrackOptionDialog(
                            isAudioMuted: _meetingStore.audioTrackStatus[
                                    filteredList[index].trackId] ==
                                HMSTrackUpdate.trackMuted,
                            isVideoMuted: map[filteredList[index].trackId] ==
                                HMSTrackUpdate.trackMuted,
                            peerName: filteredList[index].peer?.name ?? '',
                            changeTrack: (mute, isVideoTrack) {
                              Navigator.pop(context);
                              if (filteredList[index].source !=
                                  HMSTrackSource.kHMSTrackSourceScreen)
                                _meetingStore.changeTrackRequest(
                                    filteredList[index].peer?.peerId ?? "",
                                    mute,
                                    isVideoTrack);
                            },
                            removePeer: () {
                              Navigator.pop(context);
                              _meetingStore.removePeerFromRoom(
                                  filteredList[index].peer!.peerId);
                            }),
                      ],
                    ));
        },
        child: PeerItemOrganism(
            key: Key(index.toString()),
            height: itemHeight,
            width: itemWidth,
            track: filteredList[index],
            isVideoMuted: filteredList[index].peer!.isLocal
                ? !_meetingStore.isVideoOn
                : (map[filteredList[index].trackId]) ==
                    HMSTrackUpdate.trackMuted),
      ),
    );
  }
}
