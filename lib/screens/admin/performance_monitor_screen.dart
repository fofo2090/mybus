import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/database_service.dart';
import '../../services/rate_limit_service.dart';
import '../../services/cache_service.dart';

class PerformanceMonitorScreen extends StatefulWidget {
  const PerformanceMonitorScreen({super.key});

  @override
  State<PerformanceMonitorScreen> createState() => _PerformanceMonitorScreenState();
}

class _PerformanceMonitorScreenState extends State<PerformanceMonitorScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final RateLimitService _rateLimitService = RateLimitService();
  final CacheService _cacheService = CacheService();
  
  Map<String, dynamic> _cacheStats = {};
  Map<String, dynamic> _rateLimitStats = {};
  Map<String, dynamic> _memoryStats = {};
  List<Map<String, dynamic>> _violations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? 'admin';
      
      // Get cache statistics
      _cacheStats = _cacheService.getStats();
      
      // Get rate limit statistics
      _rateLimitStats = _rateLimitService.getAllRateLimitStatus(currentUserId);
      
      // Get memory statistics
      _memoryStats = _rateLimitService.getMemoryStats();
      
      // Get rate limit violations
      _violations = await _rateLimitService.getRateLimitViolations();
      
    } catch (e) {
      debugPrint('❌ Error loading performance stats: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مراقبة الأداء'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_cache',
                child: Text('مسح الذاكرة المؤقتة'),
              ),
              const PopupMenuItem(
                value: 'clear_violations',
                child: Text('مسح سجل المخالفات'),
              ),
              const PopupMenuItem(
                value: 'reset_limits',
                child: Text('إعادة تعيين الحدود'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCacheStatsCard(),
                    const SizedBox(height: 16),
                    _buildRateLimitStatsCard(),
                    const SizedBox(height: 16),
                    _buildMemoryStatsCard(),
                    const SizedBox(height: 16),
                    _buildViolationsCard(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCacheStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.storage, color: Colors.green[600]),
                const SizedBox(width: 8),
                const Text(
                  'إحصائيات الذاكرة المؤقتة',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatRow('عدد العناصر المحفوظة', '${_cacheStats['memoryEntries'] ?? 0}'),
            _buildStatRow('معدل النجاح', '${_cacheStats['hitRate'] ?? 0}%'),
            _buildStatRow('النجاحات', '${_cacheStats['hits'] ?? 0}'),
            _buildStatRow('الإخفاقات', '${_cacheStats['misses'] ?? 0}'),
            _buildStatRow('الطرد من الذاكرة', '${_cacheStats['evictions'] ?? 0}'),
            _buildStatRow('الحجم المستخدم', '${_cacheStats['totalSizeKB'] ?? 0} KB'),
            _buildStatRow('متوسط الوصول', '${_cacheStats['averageAccessCount'] ?? 0}'),
          ],
        ),
      ),
    );
  }

  Widget _buildRateLimitStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.speed, color: Colors.orange[600]),
                const SizedBox(width: 8),
                const Text(
                  'إحصائيات تحديد المعدل',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_rateLimitStats.isEmpty)
              const Text('لا توجد بيانات متاحة')
            else
              ..._rateLimitStats.entries.map((entry) => 
                _buildRateLimitOperationCard(entry.key, entry.value)
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRateLimitOperationCard(String operation, dynamic status) {
    if (status is! Map<String, dynamic>) return const SizedBox.shrink();
    
    final canMakeRequest = status['canMakeRequest'] ?? true;
    final minuteRequests = status['minuteRequests'] ?? 0;
    final maxPerMinute = status['maxPerMinute'] ?? 0;
    final remainingMinute = status['remainingMinute'] ?? 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: canMakeRequest ? Colors.green[50] : Colors.red[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            operation,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text('الطلبات في الدقيقة: $minuteRequests / $maxPerMinute'),
          Text('المتبقي: $remainingMinute'),
          Text(
            'الحالة: ${canMakeRequest ? "متاح" : "محظور"}',
            style: TextStyle(
              color: canMakeRequest ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.memory, color: Colors.purple[600]),
                const SizedBox(width: 8),
                const Text(
                  'إحصائيات الذاكرة',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatRow('عمليات المستخدم الفريدة', '${_memoryStats['uniqueUserOperations'] ?? 0}'),
            _buildStatRow('إدخالات الدقيقة', '${_memoryStats['totalMinuteEntries'] ?? 0}'),
            _buildStatRow('إدخالات الساعة', '${_memoryStats['totalHourlyEntries'] ?? 0}'),
            _buildStatRow('استخدام الذاكرة', '${_memoryStats['memoryUsageKB'] ?? 0} KB'),
          ],
        ),
      ),
    );
  }

  Widget _buildViolationsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.red[600]),
                const SizedBox(width: 8),
                Text(
                  'مخالفات الحد الأقصى (${_violations.length})',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_violations.isEmpty)
              const Text('لا توجد مخالفات')
            else
              ..._violations.take(10).map((violation) => 
                _buildViolationItem(violation)
              ),
            if (_violations.length > 10)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'و ${_violations.length - 10} مخالفة أخرى...',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildViolationItem(Map<String, dynamic> violation) {
    final timestamp = DateTime.parse(violation['timestamp']);
    final operation = violation['operation'];
    final limitType = violation['limitType'];
    final currentCount = violation['currentCount'];
    final maxAllowed = violation['maxAllowed'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red[200]!),
        borderRadius: BorderRadius.circular(4),
        color: Colors.red[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$operation - $limitType',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text('العدد: $currentCount / $maxAllowed'),
          Text(
            '${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Future<void> _handleMenuAction(String action) async {
    switch (action) {
      case 'clear_cache':
        await _cacheService.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم مسح الذاكرة المؤقتة')),
        );
        break;
      case 'clear_violations':
        await _rateLimitService.clearRateLimitViolations();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم مسح سجل المخالفات')),
        );
        break;
      case 'reset_limits':
        final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? 'admin';
        _rateLimitService.resetUserRateLimits(currentUserId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إعادة تعيين الحدود')),
        );
        break;
    }
    await _loadStats();
  }
}
