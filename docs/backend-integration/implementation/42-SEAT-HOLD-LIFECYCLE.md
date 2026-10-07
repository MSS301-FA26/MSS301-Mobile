# Hold lifecycle

Selection -> POST hold -> bookingId + holdExpiresAt -> active, conflict, expiry, or explicit cancel. `holdExpiresAt` is authoritative. Production stops after a real hold; Batch 06 owns Checkout.
