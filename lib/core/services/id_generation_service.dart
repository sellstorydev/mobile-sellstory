import 'package:cloud_firestore/cloud_firestore.dart';

class IdGenerationRules {
  final String dateFormat;
  final String generationMode;
  final int minLength;
  final String prefix;
  final String separator;

  IdGenerationRules({
    required this.dateFormat,
    required this.generationMode,
    required this.minLength,
    required this.prefix,
    required this.separator,
  });

  factory IdGenerationRules.fromMap(Map<String, dynamic> map) {
    return IdGenerationRules(
      dateFormat: map['dateFormat'] as String? ?? 'YYMMDD',
      generationMode: map['generationMode'] as String? ?? 'auto-editable',
      minLength: map['minLength'] as int? ?? 4,
      prefix: map['prefix'] as String? ?? 'CUS',
      separator: map['separator'] as String? ?? '-',
    );
  }
}

class IdGenerationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch ID generation rules from Firestore
  Future<IdGenerationRules> getIdGenerationRules(String workspaceId, String entityType) async {
    try {
      final doc = await _firestore
          .collection('workspaces')
          .doc(workspaceId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final companyProfile = data['companyProfile'] as Map<String, dynamic>?;
        
        if (companyProfile != null) {
          final idGenerationRules = companyProfile['idGenerationRules'] as Map<String, dynamic>?;
          
          if (idGenerationRules != null && idGenerationRules[entityType] != null) {
            return IdGenerationRules.fromMap(idGenerationRules[entityType] as Map<String, dynamic>);
          }
        }
      }
      
      // Return default rules if not found
      return IdGenerationRules(
        dateFormat: 'YYMMDD',
        generationMode: 'auto-editable',
        minLength: 4,
        prefix: 'CUS',
        separator: '-',
      );
    } catch (e) {
      print('Error fetching ID generation rules: $e');
      // Return default rules on error
      return IdGenerationRules(
        dateFormat: 'YYMMDD',
        generationMode: 'auto-editable',
        minLength: 4,
        prefix: 'CUS',
        separator: '-',
      );
    }
  }

  /// Generate a customer ID based on the rules
  Future<String> generateCustomerId(String workspaceId) async {
    try {
      // Get the rules
      final rules = await getIdGenerationRules(workspaceId, 'customer');
      
      // Get the current sequence number
      final sequence = await _getNextSequence(workspaceId, 'customer');
      
      // Format the date according to the rules
      final dateString = _formatDate(DateTime.now(), rules.dateFormat);
      
      // Format the sequence number with leading zeros
      final sequenceString = sequence.toString().padLeft(rules.minLength, '0');
      
      // Combine all parts
      return '${rules.prefix}${rules.separator}$dateString${rules.separator}$sequenceString';
    } catch (e) {
      print('Error generating customer ID: $e');
      // Fallback to simple ID generation
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return 'CUS-$timestamp';
    }
  }

  /// Generate a company ID based on the rules
  Future<String> generateCompanyId(String workspaceId) async {
    try {
      // Get the rules
      final rules = await getIdGenerationRules(workspaceId, 'company');
      
      // Get the current sequence number
      final sequence = await _getNextSequence(workspaceId, 'company');
      
      // Format the date according to the rules
      final dateString = _formatDate(DateTime.now(), rules.dateFormat);
      
      // Format the sequence number with leading zeros
      final sequenceString = sequence.toString().padLeft(rules.minLength, '0');
      
      // Combine all parts
      return '${rules.prefix}${rules.separator}$dateString${rules.separator}$sequenceString';
    } catch (e) {
      print('Error generating company ID: $e');
      // Fallback to simple ID generation
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return 'COM-$timestamp';
    }
  }

  /// Generate a product SKU based on the rules
  Future<String> generateProductSku(String workspaceId) async {
    try {
      // Get the rules
      final rules = await getIdGenerationRules(workspaceId, 'product');
      
      // Get the current sequence number
      final sequence = await _getNextSequence(workspaceId, 'product');
      
      // Format the date according to the rules
      final dateString = _formatDate(DateTime.now(), rules.dateFormat);
      
      // Format the sequence number with leading zeros
      final sequenceString = sequence.toString().padLeft(rules.minLength, '0');
      
      // Combine all parts
      return '${rules.prefix}${rules.separator}$dateString${rules.separator}$sequenceString';
    } catch (e) {
      print('Error generating product SKU: $e');
      // Fallback to simple ID generation
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return 'P-$timestamp';
    }
  }

  /// Generate a document document number based on the rules
  Future<String> generateDocumentDocNo(String workspaceId, String documentType) async {
    try {
      // Get the rules
      final rules = await getIdGenerationRules(workspaceId, documentType);
      
      // Get the current sequence number
      final sequence = await _getNextSequence(workspaceId, documentType);
      
      // Format the date according to the rules
      final dateString = _formatDate(DateTime.now(), rules.dateFormat);
      
      // Format the sequence number with leading zeros
      final sequenceString = sequence.toString().padLeft(rules.minLength, '0');
      
      // Combine all parts
      return '${rules.prefix}${rules.separator}$dateString${rules.separator}$sequenceString';
    } catch (e) {
      print('Error generating document document number: $e');
      // Fallback to simple ID generation
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return 'DOC-$timestamp';
    }
  }

  /// Generate an invoice document number based on the rules
  Future<String> generateInvoiceDocNo(String workspaceId) async {
    try {
      // Get the rules
      final rules = await getIdGenerationRules(workspaceId, 'invoice');
      
      // Get the current sequence number
      final sequence = await _getNextSequence(workspaceId, 'invoice');
      
      // Format the date according to the rules
      final dateString = _formatDate(DateTime.now(), rules.dateFormat);
      
      // Format the sequence number with leading zeros
      final sequenceString = sequence.toString().padLeft(rules.minLength, '0');
      
      // Combine all parts
      return '${rules.prefix}${rules.separator}$dateString${rules.separator}$sequenceString';
    } catch (e) {
      print('Error generating invoice document number: $e');
      // Fallback to simple ID generation
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return 'INV-$timestamp';
    }
  }

  /// Generate a receipt document number based on the rules
  Future<String> generateReceiptDocNo(String workspaceId) async {
    try {
      // Get the rules
      final rules = await getIdGenerationRules(workspaceId, 'receipt');
      
      // Get the current sequence number
      final sequence = await _getNextSequence(workspaceId, 'receipt');
      
      // Format the date according to the rules
      final dateString = _formatDate(DateTime.now(), rules.dateFormat);
      
      // Format the sequence number with leading zeros
      final sequenceString = sequence.toString().padLeft(rules.minLength, '0');
      
      // Combine all parts
      return '${rules.prefix}${rules.separator}$dateString${rules.separator}$sequenceString';
    } catch (e) {
      print('Error generating receipt document number: $e');
      // Fallback to simple ID generation
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return 'RE-$timestamp';
    }
  }

  /// Get the next sequence number from lastUsedCounters
  Future<int> _getNextSequence(String workspaceId, String entityType) async {
    try {
      final docRef = _firestore
          .collection('workspaces')
          .doc(workspaceId);

      final result = await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        
        int currentSequence = 0;
        if (doc.exists) {
          final data = doc.data()!;
          final companyProfile = data['companyProfile'] as Map<String, dynamic>?;
          
          if (companyProfile != null) {
            final lastUsedCounters = companyProfile['lastUsedCounters'] as Map<String, dynamic>?;
            if (lastUsedCounters != null) {
              currentSequence = (lastUsedCounters[entityType] as int?) ?? 0;
            }
          }
        }
        
        // Increment the sequence
        final newSequence = currentSequence + 1;
        
        // Update the counter in the companyProfile field
        final updateData = {
          'companyProfile.lastUsedCounters.$entityType': newSequence,
        };
        transaction.update(docRef, updateData);
        
        return newSequence;
      });

      return result;
    } catch (e) {
      print('Error getting sequence from lastUsedCounters: $e');
      // Fallback to timestamp-based sequence
      return DateTime.now().millisecondsSinceEpoch % 10000;
    }
  }

  /// Format date according to the specified format
  String _formatDate(DateTime date, String format) {
    switch (format) {
      case 'YYMMDD':
        return '${date.year.toString().substring(2)}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
      case 'YYYYMMDD':
        return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
      case 'DDMMYY':
        return '${date.day.toString().padLeft(2, '0')}${date.month.toString().padLeft(2, '0')}${date.year.toString().substring(2)}';
      case 'MMDDYY':
        return '${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}${date.year.toString().substring(2)}';
      default:
        return '${date.year.toString().substring(2)}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
    }
  }
}
