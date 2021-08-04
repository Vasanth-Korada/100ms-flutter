import 'package:flutter/material.dart';
import 'package:hmssdk_flutter/model/hms_role_change_request.dart';

class RoleChangeDialogOrganism extends StatefulWidget {
  final HMSRoleChangeRequest roleChangeRequest;
  const RoleChangeDialogOrganism({required this.roleChangeRequest}) : super();

  @override
  _RoleChangeDialogOrganismState createState() => _RoleChangeDialogOrganismState();
}

class _RoleChangeDialogOrganismState extends State<RoleChangeDialogOrganism> {


  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Container(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Change Role request"),
            Text(widget.roleChangeRequest.suggestedBy.name.toString()),
            Text(widget.roleChangeRequest.suggestedRole.name)
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          child: Text('Cancel'),
          onPressed: () {
            Navigator.pop(context,'');
          },
        ),
        ElevatedButton(
          child: Text('Ok'),
          onPressed: () {
            Navigator.pop(context,'Ok');
          },
        ),
      ],
    );
  }
}
