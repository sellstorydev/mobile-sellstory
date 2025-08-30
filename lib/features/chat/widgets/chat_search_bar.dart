import 'package:flutter/material.dart';

class ChatSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onOpenFilter;

  const ChatSearchBar({
    Key? key,
    required this.controller,
    required this.onChanged,
    required this.onOpenFilter,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'ค้นหาด้วย ชื่อ นามสกุล ชื่อบริษัท หรือ ข้อความแชท hashtag เซล',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                fillColor: Colors.white,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.blue, width: 1.8),
                ),
              ),
              onChanged: onChanged,
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onOpenFilter,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.tune_rounded),
              ),
            ),
          )
        ],
      ),
    );
  }
}

