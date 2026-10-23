import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// removed hexcolor import; use Theme colors instead

Widget buildSearchBar(BuildContext context, String labelText) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10),
    child: Container(
      width: 400,
      height: 64,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1.0,
        ),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Enter your keyword',
          hintStyle: TextStyle(color: Theme.of(context).hintColor),
          prefixIcon: Icon(
            CupertinoIcons.search,
            size: 24,
            color: Theme.of(context).iconTheme.color,
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.transparent),
            borderRadius: BorderRadius.circular(20),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.transparent),
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
        ),
      ),
    ),
  );
}
