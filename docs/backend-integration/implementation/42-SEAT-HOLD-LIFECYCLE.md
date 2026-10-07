# Hold lifecycle

Selection -> POST hold -> bookingId + holdExpiresAt -> active, conflict, expiry, explicit cancel, or real checkout quote. `holdExpiresAt` is authoritative. Production now continues through the real quote and stops before Payment.
