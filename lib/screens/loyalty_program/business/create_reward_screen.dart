import 'package:flutter/material.dart';

class CreateRewardScreen extends StatefulWidget {
  const CreateRewardScreen({super.key});

  @override
  State<CreateRewardScreen> createState() => _CreateRewardScreenState();
}

class _CreateRewardScreenState extends State<CreateRewardScreen> {
  String rewardType = "Stamp";

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  final stampController = TextEditingController();
  final pointsController = TextEditingController();

  DateTime? expiryDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Create Reward",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TITLE
            _label("Reward Title"),
            const SizedBox(height: 8),
            _input(titleController, "e.g. Free Coffee"),

            const SizedBox(height: 16),

            // DESCRIPTION
            _label("Description"),
            const SizedBox(height: 8),
            _input(descriptionController, "Short description", maxLines: 3),

            const SizedBox(height: 20),

            // TYPE SELECTOR
            _label("Reward Type"),
            const SizedBox(height: 10),

            Row(
              children: [
                _typeChip("Stamp"),
                const SizedBox(width: 10),
                _typeChip("Points"),
                const SizedBox(width: 10),
                _typeChip("Both"),
              ],
            ),

            const SizedBox(height: 25),

            // RULES SECTION
            _label("Reward Conditions"),
            const SizedBox(height: 10),

            if (rewardType == "Stamp" || rewardType == "Both")
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Required Stamps"),
                  const SizedBox(height: 8),
                  _input(
                    stampController,
                    "e.g. 10",
                    keyboard: TextInputType.number,
                  ),
                  const SizedBox(height: 15),
                ],
              ),

            if (rewardType == "Points" || rewardType == "Both")
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Required Points"),
                  const SizedBox(height: 8),
                  _input(
                    pointsController,
                    "e.g. 500",
                    keyboard: TextInputType.number,
                  ),
                  const SizedBox(height: 15),
                ],
              ),

            // EXPIRY DATE
            _label("Expiry Date"),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (date != null) {
                  setState(() {
                    expiryDate = date;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month),
                    const SizedBox(width: 10),
                    Text(
                      expiryDate == null
                          ? "Select Expiry Date"
                          : expiryDate.toString().split(" ")[0],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            // PREVIEW CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Preview",
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    titleController.text.isEmpty
                        ? "Reward Title"
                        : titleController.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    rewardType,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // CREATE BUTTON
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  "Create Reward",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeChip(String type) {
    final isSelected = rewardType == type;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            rewardType = type;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected ? Colors.black : Colors.white,
            border: Border.all(color: Colors.black),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              type,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _input(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboard,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    );
  }
}
