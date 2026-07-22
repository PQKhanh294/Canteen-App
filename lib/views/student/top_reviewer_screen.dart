import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';

class TopReviewerScreen extends StatelessWidget {
  const TopReviewerScreen({super.key});

  Future<List<Map<String, dynamic>>> _fetchTopReviewers() async {
    final snap = await FirebaseFirestore.instance
        .collection(AppConstants.reviewsCollection)
        .get();

    final Map<String, Map<String, dynamic>> reviewerMap = {};
    for (final doc in snap.docs) {
      final data = doc.data();
      final userId = (data['userId'] as String?) ?? '';
      final userName = (data['userName'] as String?) ?? 'Sinh viên';
      if (userId.isEmpty) continue;
      if (reviewerMap.containsKey(userId)) {
        reviewerMap[userId]!['count'] = (reviewerMap[userId]!['count'] as int) + 1;
        final totalRating = (reviewerMap[userId]!['totalRating'] as double) + ((data['rating'] as num?)?.toDouble() ?? 0);
        reviewerMap[userId]!['totalRating'] = totalRating;
      } else {
        reviewerMap[userId] = {
          'userId': userId,
          'userName': userName,
          'count': 1,
          'totalRating': (data['rating'] as num?)?.toDouble() ?? 0.0,
        };
      }
    }

    final list = reviewerMap.values.toList();
    list.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    return list.take(10).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Static sample leaderboard data for demo (shown when Firestore is empty)
    final sampleLeaderboard = [
      {'rank': 1, 'name': 'Phạm Quang Khánh', 'count': 42, 'avgRating': 4.9, 'badge': '🥇'},
      {'rank': 2, 'name': 'Nguyễn Hoài An', 'count': 37, 'avgRating': 4.8, 'badge': '🥈'},
      {'rank': 3, 'name': 'Vũ Đình Quý', 'count': 31, 'avgRating': 4.7, 'badge': '🥉'},
      {'rank': 4, 'name': 'Trần Văn Hài', 'count': 28, 'avgRating': 4.8, 'badge': ''},
      {'rank': 5, 'name': 'Hoàng Mỹ Linh', 'count': 24, 'avgRating': 4.6, 'badge': ''},
      {'rank': 6, 'name': 'Bùi Đức Nam', 'count': 19, 'avgRating': 4.7, 'badge': ''},
      {'rank': 7, 'name': 'Đặng Anh Tuấn', 'count': 17, 'avgRating': 4.5, 'badge': ''},
      {'rank': 8, 'name': 'Nguyễn Thu Trang', 'count': 15, 'avgRating': 4.6, 'badge': ''},
      {'rank': 9, 'name': 'Lê Minh Hoàng', 'count': 12, 'avgRating': 4.4, 'badge': ''},
      {'rank': 10, 'name': 'Nguyễn Khánh Linh', 'count': 10, 'avgRating': 4.5, 'badge': ''},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('🏆 Bảng Xếp Hạng Reviewer'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchTopReviewers(),
        builder: (context, snapshot) {
          // Determine which data to show
          List<Map<String, dynamic>> displayData;

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 12),
                  Text('Đang tải bảng xếp hạng...', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          final firestoreData = snapshot.data ?? [];
          if (firestoreData.length >= 3) {
            // Build display from Firestore
            displayData = firestoreData.asMap().entries.map((entry) {
              final i = entry.key;
              final r = entry.value;
              final count = r['count'] as int;
              final totalRating = r['totalRating'] as double;
              final avgRating = count > 0 ? totalRating / count : 0.0;
              String badge = '';
              if (i == 0) badge = '🥇';
              else if (i == 1) badge = '🥈';
              else if (i == 2) badge = '🥉';
              return {
                'rank': i + 1,
                'name': r['userName'],
                'count': count,
                'avgRating': double.parse(avgRating.toStringAsFixed(1)),
                'badge': badge,
              };
            }).toList();
          } else {
            displayData = sampleLeaderboard;
          }

          return Column(
            children: [
              // Top 3 Podium
              if (displayData.length >= 3)
                _buildPodium(displayData[0], displayData[1], displayData[2]),
              const SizedBox(height: 8),
              // Rank 4-10 List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: displayData.length > 3 ? displayData.length - 3 : 0,
                  itemBuilder: (context, index) {
                    final item = displayData[index + 3];
                    return _buildRankItem(item);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPodium(
    Map<String, dynamic> first,
    Map<String, dynamic> second,
    Map<String, dynamic> third,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8F00), Color(0xFFFF6F00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildPodiumItem(second, 2, 80),
          _buildPodiumItem(first, 1, 110),
          _buildPodiumItem(third, 3, 70),
        ],
      ),
    );
  }

  Widget _buildPodiumItem(Map<String, dynamic> item, int rank, double height) {
    final colors = [
      const Color(0xFFFFD700), // Gold
      const Color(0xFFC0C0C0), // Silver
      const Color(0xFFCD7F32), // Bronze
    ];
    final color = colors[rank - 1];
    final name = (item['name'] as String).split(' ').last;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: rank == 1 ? 32 : 26,
          backgroundColor: color,
          child: Text(
            name[0].toUpperCase(),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: rank == 1 ? 22 : 16,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        Text(
          '${item['count']} đánh giá',
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
        const SizedBox(height: 4),
        Text(
          ['🥇', '🥈', '🥉'][rank - 1],
          style: const TextStyle(fontSize: 20),
        ),
      ],
    );
  }

  Widget _buildRankItem(Map<String, dynamic> item) {
    final rank = item['rank'] as int;
    final name = item['name'] as String;
    final count = item['count'] as int;
    final avgRating = item['avgRating'];
    final avgRatingDouble = avgRating is double ? avgRating : (avgRating as num).toDouble();
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'U';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            alignment: Alignment.center,
            child: Text(
              '#$rank',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primaryLight,
            child: Text(
              initial,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '$count đánh giá · ⭐ ${avgRatingDouble.toStringAsFixed(1)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Reviewer tier badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: count >= 30
                  ? const Color(0xFFFF8F00).withOpacity(0.15)
                  : count >= 15
                      ? AppColors.primaryLight
                      : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              count >= 30
                  ? '⭐ Expert'
                  : count >= 15
                      ? '🔥 Active'
                      : '✏️ Starter',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: count >= 30
                    ? const Color(0xFFFF8F00)
                    : count >= 15
                        ? AppColors.primary
                        : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
