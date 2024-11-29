import 'package:flutter/material.dart';

import '../../constant/custom_colors.dart';
import '../../model/leave.dart';
import '../../utils/general_helper.dart';
import '../custom/custom_card.dart';
import '../responsive/responsive_icon.dart';
import '../responsive/responsive_text.dart';

class LeaveItem extends StatelessWidget {
  final Leave leave;
  final Function(Leave) onClick;
  const LeaveItem({Key? key, required this.leave, required this.onClick}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20),
      child: CustomCard(
        padding: EdgeInsets.all(0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              onClick(leave);
            },
            borderRadius: BorderRadius.circular(16),
            highlightColor: CustomColor.gray50,
            splashColor: CustomColor.gray50,
            child: Container(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ResponsiveText(
                          "${leave.nama!}",
                          style: TextStyle(fontWeight: FontWeight.w500, color: CustomColor.gray700),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        SizedBox(height: 3,),
                        ResponsiveText(
                          "Cuti ${leave.durasi!} Hari",
                          style: TextStyle(fontWeight: FontWeight.w500, color: CustomColor.gray400),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        SizedBox(height: 3,),
                        ResponsiveText(
                          "${GeneralHelper.convertDate(leave.tgl_mulai!)} - ${GeneralHelper.convertDate(leave.tgl_selesai!)}",
                          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black, fontSize: 18),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        SizedBox(height: 6,),
                        ResponsiveText(
                          leave.keterangan!,
                          style: TextStyle(fontWeight: FontWeight.w500, color: CustomColor.gray500),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: leave.status! == "Disetujui"
                              ? CustomColor.success.withOpacity(0.25)
                              : leave.status! == "Ditolak"
                              ? CustomColor.error.withOpacity(0.25)
                              : CustomColor.warn.withOpacity(0.25),
                        ),
                        child: ResponsiveText(
                          leave.status!,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: leave.status! == "Disetujui"
                                ? CustomColor.success
                                : leave.status! == "Ditolak"
                                ? CustomColor.error
                                : CustomColor.warn,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      SizedBox(height: 6),
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          color: CustomColor.gray50,
                        ),
                        child: ResponsiveIcon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: CustomColor.gray400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
