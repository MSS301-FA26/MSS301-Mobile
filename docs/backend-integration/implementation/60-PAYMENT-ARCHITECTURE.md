# Payment architecture

Production flow is real checkout quote -> VNPay payment creation -> backend payment URL -> provider return -> backend payment status. The mobile app stops at payment status; order/history remains the next boundary.
