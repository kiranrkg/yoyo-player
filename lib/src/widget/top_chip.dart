import 'package:flutter/material.dart';

Widget topchip(BuildContext context, Widget data, Function fun) {
  return InkWell(
    onTap: fun,
    child: Container(
      decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(5)),
      child: Padding(
        padding: const EdgeInsets.all(3.0),
        child: data,
      ),
    ),
  );
}
