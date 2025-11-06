import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/bucket_config.dart';
import '../bloc/library_bloc.dart';

class BucketsPage extends StatelessWidget {
  const BucketsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('S3 Buckets'),
      ),
      body: BlocBuilder<LibraryBloc, LibraryState>(
        builder: (context, state) {
          final buckets = _getBuckets(state);
          final currentBucket = _getCurrentBucket(state);

          if (buckets.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            itemCount: buckets.length,
            itemBuilder: (context, index) {
              final bucket = buckets[index];
              final isSelected = currentBucket?.name == bucket.name;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: isSelected ? 4 : 1,
                color: isSelected 
                    ? Theme.of(context).colorScheme.primaryContainer 
                    : null,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.secondaryContainer,
                    child: Icon(
                      isSelected ? Icons.check : Icons.folder,
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                  title: Text(
                    bucket.name,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Region: ${bucket.region}'),
                      if (bucket.trackCount > 0)
                        Text('${bucket.trackCount} tracks'),
                      if (bucket.lastScanned != null)
                        Text(
                          'Last scanned: ${_formatDate(bucket.lastScanned!)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isSelected)
                        IconButton(
                          icon: const Icon(Icons.play_arrow),
                          tooltip: 'Use this bucket',
                          onPressed: () {
                            context.read<LibraryBloc>().add(
                              SwitchBucketEvent(bucket),
                            );
                            Navigator.pop(context);
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Delete bucket',
                        onPressed: () {
                          _showDeleteDialog(context, bucket);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBucketDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Bucket'),
      ),
    );
  }

  List<BucketConfig> _getBuckets(LibraryState state) {
    if (state is LibraryLoaded) {
      return state.buckets;
    }
    if (state is LibraryRefreshing) {
      return state.buckets;
    }
    return [];
  }

  BucketConfig? _getCurrentBucket(LibraryState state) {
    if (state is LibraryLoaded) {
      return state.currentBucket;
    }
    if (state is LibraryRefreshing) {
      return state.currentBucket;
    }
    return null;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 80,
            color: Colors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No buckets configured',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add an S3 bucket to get started',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddBucketDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Bucket'),
          ),
        ],
      ),
    );
  }

  void _showAddBucketDialog(BuildContext context) {
    final nameController = TextEditingController();
    final regionController = TextEditingController(text: 'ap-southeast-2');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add S3 Bucket'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Bucket Name',
                hintText: 'my-music-bucket',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: regionController,
              decoration: const InputDecoration(
                labelText: 'AWS Region',
                hintText: 'ap-southeast-2',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'The bucket must be publicly accessible',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final region = regionController.text.trim();

              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a bucket name')),
                );
                return;
              }

              Navigator.pop(dialogContext);

              // Add and scan the bucket
              context.read<LibraryBloc>().add(
                AddBucketEvent(
                  bucketName: name,
                  region: region,
                ),
              );
            },
            child: const Text('Add & Scan'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, BucketConfig bucket) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Bucket'),
        content: Text(
          'Are you sure you want to remove "${bucket.name}"? This will not delete the actual S3 bucket.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<LibraryBloc>().add(
                DeleteBucketEvent(bucket.name),
              );
              Navigator.pop(dialogContext);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
