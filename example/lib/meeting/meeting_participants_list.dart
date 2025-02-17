//Package imports
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

//Project imports
import 'package:hmssdk_flutter/hmssdk_flutter.dart';
import 'package:hmssdk_flutter_example/common/ui/organisms/participant_organism.dart';
import 'package:hmssdk_flutter_example/meeting/meeting_store.dart';

class ParticipantsList extends StatefulWidget {
  final MeetingStore meetingStore;

  const ParticipantsList({Key? key, required this.meetingStore})
      : super(key: key);

  @override
  _ParticipantsListState createState() => _ParticipantsListState();
}

class _ParticipantsListState extends State<ParticipantsList> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Participants"),
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        child: SingleChildScrollView(
          child: Observer(builder: (_) {
            List<HMSPeer> peers = widget.meetingStore.peers;
            if (peers.isNotEmpty) {
              return ListView(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                children: peers
                    .map((peer) => ParticipantOrganism(
                          peer: peer,
                          meetingStore: widget.meetingStore,
                        ))
                    .toList(),
              );
            } else {
              return Text(("No Participants"));
            }
          }),
        ),
      ),
    );
  }
}
