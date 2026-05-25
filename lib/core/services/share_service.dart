import 'package:share_plus/share_plus.dart';
import '../../data/models/job_model.dart';

class ShareService {
  // Custom URL scheme — free, no Apple Developer account needed.
  // Works from iMessage, WhatsApp, email, etc.
  // Triple slash = empty host, so go_router sees path /jobs/:id correctly.
  // jobscope://jobs/abc  → path is /abc  ❌
  // jobscope:///jobs/abc → path is /jobs/abc ✓
  static const _baseUrl = 'jobscope:///jobs';

  Future<void> shareJob(JobModel job) async {
    final url = '$_baseUrl/${job.id}';
    await Share.share(
      _buildText(job, url),
      subject: '${job.title} at ${job.company} — JobScope',
    );
  }

  String _buildText(JobModel job, String url) {
    final buf = StringBuffer();
    buf.writeln('${job.title} at ${job.company}');
    buf.writeln('${job.location} · ${_fmt(job.jobType)}');
    if (job.salaryMin != null || job.salaryMax != null) {
      buf.writeln(job.salaryRange);
    }
    buf.writeln();
    buf.writeln('View on JobScope:');
    buf.write(url);
    return buf.toString();
  }

  String _fmt(String type) {
    switch (type.toLowerCase()) {
      case 'full-time':
        return 'Full-time';
      case 'part-time':
        return 'Part-time';
      case 'remote':
        return 'Remote';
      case 'contract':
        return 'Contract';
      default:
        return type;
    }
  }
}
