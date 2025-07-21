# Main namespace policies for Atlantis/Conftest integration
package main

# Import existing terraform policies
import data.terraform.security
import data.terraform.cost_control

# Re-export deny rules for main namespace
deny[msg] {
    security.deny[msg]
}

deny[msg] {
    cost_control.deny[msg]
}

# Re-export warn rules for main namespace  
warn[msg] {
    security.warn[msg]
}

warn[msg] {
    cost_control.warn[msg]
}
