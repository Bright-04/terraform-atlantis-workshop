# Policy Testing

This change will trigger Atlantis to re-run the plan with policy validation enabled.

Policy checks are now enabled in Atlantis:
- ATLANTIS_ENABLE_POLICY_CHECKS=true 
- Expected to detect 10 failures and 3 warnings
- Should block terraform apply until policies pass

Test timestamp: 2025-07-21T03:53:00Z
