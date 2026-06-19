import 'package:flutter/material.dart';

class CustomerRewardScreen extends StatelessWidget {
  const CustomerRewardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const int currentStamps = 7;
    const int totalStamps = 10;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        // title: const Text(
        //   'Add Stamp',
        //   style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        // ),
        // backgroundColor: Colors.white,
        // surfaceTintColor: Colors.white,
        // elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    "https://template.canva.com/EAGOADQey2g/1/0/1600w-BiB84MUi2zQ.jpg",
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  "Rembiro",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),

          /// 🔵 STAMP GRID (Loopy Style)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.amber),

            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 14,
              runSpacing: 14,
              children: List.generate(totalStamps, (index) {
                final bool isFilled = index < currentStamps;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: isFilled ? Colors.black : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 1.5),
                    boxShadow: [
                      if (isFilled)
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.coffee,
                      color: isFilled ? Colors.white : Colors.black,
                      size: 26,
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 30),

          /// STATUS TEXT
          Text(
            currentStamps == totalStamps
                ? 'Reward Unlocked 🎉'
                : '${totalStamps - currentStamps} stamps left',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),

          // const SizedBox(height: 10),

          // LinearProgressIndicator(
          //   value: currentStamps / totalStamps,
          //   backgroundColor: Colors.grey.shade200,
          //   color: Colors.black,
          //   minHeight: 6,
          //   borderRadius: BorderRadius.circular(10),
          // ),
          const SizedBox(height: 50),

          // const Spacer(),

          /// ADD STAMP BUTTON
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Row(
                //   children: [
                //     CircleAvatar(
                //       child: Icon(Icons.remove, color: Colors.black),

                //       backgroundColor: Colors.white,
                //     ),
                //     const SizedBox(width: 20),
                //     Text(
                //       "1",
                //       style: TextStyle(fontSize: 28, color: Colors.white),
                //     ),
                //     const SizedBox(width: 20),
                //     CircleAvatar(
                //       child: Icon(Icons.add, color: Colors.black),
                //       backgroundColor: Colors.white,
                //     ),
                //     const SizedBox(width: 50),
                //   ],
                // ),

                // SizedBox(
                //   // width: double.infinity,
                //   // height: 55,
                //   child: ElevatedButton(
                //     style: ElevatedButton.styleFrom(
                //       backgroundColor: Colors.white,
                //       foregroundColor: Colors.black,
                //       shape: RoundedRectangleBorder(
                //         borderRadius: BorderRadius.circular(14),
                //       ),
                //     ),
                //     onPressed: () {},
                //     child: const Text(
                //       'Add Stamp',
                //       style: TextStyle(
                //         fontSize: 16,
                //         fontWeight: FontWeight.w600,
                //       ),
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
