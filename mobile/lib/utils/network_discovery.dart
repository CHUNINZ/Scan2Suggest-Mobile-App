import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class NetworkDiscovery {
  
  /// Automatically discover the backend server on the local network
  static Future<String?> discoverBackendUrl() async {
    // First try the known backend IP directly
    if (await _testUrl('http://10.196.73.221:3000/api')) {
      return 'http://10.196.73.221:3000/api';
    }
    
    // Get device's current network info and generate candidates
    List<String> candidateIps = await _generateCandidateIps();
    
    // Test each candidate IP
    for (String ip in candidateIps) {
      String testUrl = 'http://$ip:3000/api';
      if (await _testUrl(testUrl)) {
        return testUrl;
      }
    }
    
    // Fallback to predefined URLs
    for (String url in ApiConfig.possibleBaseUrls) {
      if (await _testUrl(url)) {
        return url;
      }
    }
    
    return null;
  }
  
  /// Generate candidate IP addresses based on device's network
  static Future<List<String>> _generateCandidateIps() async {
    List<String> candidates = [];
    
    try {
      // Get all network interfaces
      List<NetworkInterface> interfaces = await NetworkInterface.list();
      
      for (NetworkInterface interface in interfaces) {
        for (InternetAddress address in interface.addresses) {
          if (address.type == InternetAddressType.IPv4 && !address.isLoopback) {
            String deviceIp = address.address;
            print('📱 Device IP: $deviceIp');
            
            // Generate possible server IPs based on device IP
            List<String> subnet = deviceIp.split('.');
            if (subnet.length == 4) {
              String baseIp = '${subnet[0]}.${subnet[1]}.${subnet[2]}';
              
              // FIXED: Only try the same subnet, not 256 different subnets!
              // Common computer IP addresses (most laptops/desktops use these)
              List<int> hostRanges = [105, 100, 101, 102, 103, 104, 106, 107, 108, 109, 110, 1, 167, 169];
              
              // Add device's host number and nearby IPs first (higher priority)
              int deviceHost = int.tryParse(subnet[3]) ?? 0;
              for (int offset = -5; offset <= 5; offset++) {
                int nearbyHost = deviceHost + offset;
                if (nearbyHost > 0 && nearbyHost < 255 && !hostRanges.contains(nearbyHost)) {
                  hostRanges.insert(0, nearbyHost);
                }
              }
              
              // Only scan the SAME subnet (not all 256 subnets!)
              for (int host in hostRanges.take(20)) { // Limit to first 20 IPs
                candidates.add('$baseIp.$host');
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error discovering network interfaces: $e');
    }
    
    return candidates;
  }
  
  /// Test if a URL is reachable
  static Future<bool> _testUrl(String url) async {
    try {
      final response = await http.get(
        Uri.parse('$url/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 1)); // Reduced to 1 second for faster discovery
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
