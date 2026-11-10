import React, { useState, useEffect } from 'react';
import { BookingState, Seat, SeatAssignment, TicketSelection, TicketTypeItem } from '../types';
import { formatCurrency, handleImageError } from '../utils/format';
import { TICKET_POLICY_CONFIG, MAX_TICKETS_PER_BOOKING, SEAT_SURCHARGES } from '../data/ticketPolicyConfig';
import { CINEMA_CONFIG } from '../data/cinemaConfig';
import { BookingProgressBar } from '../components/BookingProgressBar';

interface SeatsScreenProps {
  booking: BookingState;
  onContinue: (updatedBooking: BookingState) => void;
  onBack: () => void;
}

type TicketTypeCode = 'ADULT' | 'STUDENT' | 'CHILD';

export const SeatsScreen: React.FC<SeatsScreenProps> = ({
  booking,
  onContinue,
  onBack,
}) => {
  const basePrice = booking.selectedSlot?.price || 90000;

  // Initialize ticket type metadata with dynamic pricing based on slot
  const ticketTypeDefinitions: TicketTypeItem[] = TICKET_POLICY_CONFIG.defaultTypes.map((item) => ({
    ...item,
    unitPrice: TICKET_POLICY_CONFIG.calculateUnitPrice(item.code, basePrice),
  }));

  // Quantities state for the 3 ticket types
  const [quantities, setQuantities] = useState<Record<TicketTypeCode, number>>(() => {
    const initialMap: Record<TicketTypeCode, number> = {
      ADULT: 0,
      STUDENT: 0,
      CHILD: 0,
    };

    if (booking.ticketSelections && booking.ticketSelections.length > 0) {
      booking.ticketSelections.forEach((sel) => {
        initialMap[sel.code] = sel.quantity;
      });
    } else if (booking.totalTicketQuantity && booking.totalTicketQuantity > 0) {
      initialMap.ADULT = booking.totalTicketQuantity;
    } else if (booking.ticketQuantity && booking.ticketQuantity > 0) {
      initialMap.ADULT = booking.ticketQuantity;
    } else {
      // Default to 1 Adult ticket to provide smooth, immediate UX
      initialMap.ADULT = 1;
    }

    return initialMap;
  });

  // Seat Assignments state: each seat is directly bound to a ticket type
  const [seatAssignments, setSeatAssignments] = useState<SeatAssignment[]>(() => {
    if (booking.seatAssignments && booking.seatAssignments.length > 0) {
      return booking.seatAssignments;
    }
    // Backward compatibility with legacy selectedSeats if seatAssignments was not set
    if (booking.selectedSeats && booking.selectedSeats.length > 0) {
      let order = 1;
      return booking.selectedSeats.map((s) => ({
        seatId: s.id,
        seatLabel: s.id,
        ticketTypeId: 'ticket-adult',
        ticketTypeCode: 'ADULT',
        ticketTypeName: 'Người lớn',
        ticketPrice: basePrice,
        seatSurcharge: s.type === 'vip' ? SEAT_SURCHARGES.vip : s.type === 'couple' ? SEAT_SURCHARGES.couple : 0,
        finalPrice: basePrice + (s.type === 'vip' ? SEAT_SURCHARGES.vip : s.type === 'couple' ? SEAT_SURCHARGES.couple : 0),
        assignedOrder: order++,
        seatType: s.type,
      }));
    }
    return [];
  });

  // Currently active ticket type for seat assignment
  const [activeTicketType, setActiveTicketType] = useState<TicketTypeCode | null>(() => {
    if (quantities.ADULT > 0) return 'ADULT';
    if (quantities.STUDENT > 0) return 'STUDENT';
    if (quantities.CHILD > 0) return 'CHILD';
    return null;
  });

  // Policy Condition Modal state (for Student / Child verification info)
  const [activePolicyModal, setActivePolicyModal] = useState<TicketTypeItem | null>(null);

  // Seat Action Dialog state (when tapping an already selected seat)
  const [seatActionTarget, setSeatActionTarget] = useState<{
    seat: Seat;
    assignment: SeatAssignment;
  } | null>(null);

  // Decrease Confirmation Dialog state (when decreasing count would drop an assigned seat)
  const [decreaseConfirmTarget, setDecreaseConfirmTarget] = useState<{
    code: TicketTypeCode;
    name: string;
    seatToRemove: SeatAssignment;
  } | null>(null);

  // Toast notification for auto-switching ticket types or warnings
  const [toastMessage, setToastMessage] = useState<{
    text: string;
    type?: 'info' | 'success' | 'warning';
  } | null>(null);

  // Clear toast automatically after 3.5s
  useEffect(() => {
    if (toastMessage) {
      const timer = setTimeout(() => setToastMessage(null), 3500);
      return () => clearTimeout(timer);
    }
  }, [toastMessage]);

  const showToast = (text: string, type: 'info' | 'success' | 'warning' = 'info') => {
    setToastMessage({ text, type });
  };

  // Seat Matrix Setup
  const rows = ['A', 'B', 'C', 'D', 'E'];
  const generateSeats = (): Seat[] => {
    const seats: Seat[] = [];
    rows.forEach((row) => {
      const count = row === 'E' ? 6 : 8; // Row E is couple seats
      for (let i = 1; i <= count; i++) {
        const id = `${row}${i}`;
        const isOccupied = ['A2', 'A7', 'B3', 'B4', 'D6', 'D7'].includes(id);

        let type: 'standard' | 'vip' | 'couple' = 'standard';
        let price = basePrice;

        if (['C', 'D'].includes(row)) {
          type = 'vip';
          price = basePrice + SEAT_SURCHARGES.vip;
        } else if (row === 'E') {
          type = 'couple';
          price = basePrice + SEAT_SURCHARGES.couple;
        }

        seats.push({
          id,
          row,
          col: i,
          type,
          price,
          status: isOccupied ? 'occupied' : 'available',
        });
      }
    });
    return seats;
  };

  const [allSeats] = useState<Seat[]>(generateSeats());

  // Aggregate calculations
  const totalTicketQuantity = quantities.ADULT + quantities.STUDENT + quantities.CHILD;
  const totalAssignedSeats = seatAssignments.length;
  const isMaxReached = totalTicketQuantity >= MAX_TICKETS_PER_BOOKING;

  const getAssignedCount = (code: TicketTypeCode) =>
    seatAssignments.filter((a) => a.ticketTypeCode === code).length;

  const getRemainingCount = (code: TicketTypeCode) =>
    Math.max(0, quantities[code] - getAssignedCount(code));

  // Determine if all selected tickets have been assigned a seat
  const isAllFullyAssigned =
    totalTicketQuantity > 0 &&
    totalAssignedSeats === totalTicketQuantity &&
    getRemainingCount('ADULT') === 0 &&
    getRemainingCount('STUDENT') === 0 &&
    getRemainingCount('CHILD') === 0;

  // Build missing seats description (e.g. "Còn 1 ghế Sinh viên", "Còn 2 ghế Trẻ em")
  const missingDescription = (() => {
    const missing: string[] = [];
    if (getRemainingCount('ADULT') > 0) {
      missing.push(`${getRemainingCount('ADULT')} ghế Người lớn`);
    }
    if (getRemainingCount('STUDENT') > 0) {
      missing.push(`${getRemainingCount('STUDENT')} ghế Sinh viên`);
    }
    if (getRemainingCount('CHILD') > 0) {
      missing.push(`${getRemainingCount('CHILD')} ghế Trẻ em`);
    }
    return missing.length > 0 ? `Còn thiếu ${missing.join(', ')}` : '';
  })();

  // Calculate Subtotals & Pricing directly from seatAssignments
  // Base ticket prices for assigned seats + unassigned tickets
  const ticketSubtotal =
    seatAssignments.reduce((acc, a) => acc + a.ticketPrice, 0) +
    (['ADULT', 'STUDENT', 'CHILD'] as TicketTypeCode[]).reduce((acc, code) => {
      const remainingUnassigned = getRemainingCount(code);
      const def = ticketTypeDefinitions.find((t) => t.code === code);
      return acc + remainingUnassigned * (def?.unitPrice || basePrice);
    }, 0);

  const seatSurcharge = seatAssignments.reduce((acc, a) => acc + a.seatSurcharge, 0);
  const totalTicketsAndSeatsPrice = ticketSubtotal + seatSurcharge;

  // Find next type that needs seats: ADULT -> STUDENT -> CHILD
  const findNextIncompleteType = (
    currentAssignments: SeatAssignment[],
    overrideQuantities: Record<TicketTypeCode, number> = quantities
  ): TicketTypeCode | null => {
    const order: TicketTypeCode[] = ['ADULT', 'STUDENT', 'CHILD'];
    for (const code of order) {
      const assigned = currentAssignments.filter((a) => a.ticketTypeCode === code).length;
      if (assigned < overrideQuantities[code]) {
        return code;
      }
    }
    return null;
  };

  // Handle Ticket Quantity Increase
  const handleIncreaseQuantity = (code: TicketTypeCode) => {
    if (totalTicketQuantity >= MAX_TICKETS_PER_BOOKING) {
      showToast(`Mỗi đơn chỉ được đặt tối đa ${MAX_TICKETS_PER_BOOKING} vé`, 'warning');
      return;
    }

    const nextQty = quantities[code] + 1;
    const nextQuantities = { ...quantities, [code]: nextQty };
    setQuantities(nextQuantities);

    // Automatically make this ticket type active if it wasn't or if other types are full
    setActiveTicketType(code);
    const def = ticketTypeDefinitions.find((t) => t.code === code);
    showToast(`Đã tăng ${def?.name}. Còn chọn ${nextQty - getAssignedCount(code)} ghế`, 'info');
  };

  // Handle Ticket Quantity Decrease
  const handleDecreaseQuantity = (code: TicketTypeCode) => {
    const currentQty = quantities[code];
    if (currentQty <= 0) return;

    const assignedCount = getAssignedCount(code);
    const nextQty = currentQty - 1;

    // Check if decreasing requires removing an already assigned seat
    if (assignedCount > nextQty) {
      // Find the most recently assigned seat for this ticket type
      const seatsForCode = seatAssignments
        .filter((a) => a.ticketTypeCode === code)
        .sort((a, b) => b.assignedOrder - a.assignedOrder);

      const seatToRemove = seatsForCode[0];
      const def = ticketTypeDefinitions.find((t) => t.code === code);

      setDecreaseConfirmTarget({
        code,
        name: def?.name || code,
        seatToRemove,
      });
      return;
    }

    // Normal decrease without dropping any seats
    const nextQuantities = { ...quantities, [code]: nextQty };
    setQuantities(nextQuantities);

    // If active ticket type is now at 0, switch to another available type
    if (activeTicketType === code && nextQty === 0) {
      const nextType = findNextIncompleteType(seatAssignments, nextQuantities);
      setActiveTicketType(nextType);
    }
  };

  // Confirm Dropping Seat on Quantity Decrease
  const handleConfirmDecreaseWithSeatDrop = () => {
    if (!decreaseConfirmTarget) return;
    const { code, seatToRemove } = decreaseConfirmTarget;

    // Remove the most recently assigned seat
    const updatedAssignments = seatAssignments.filter((a) => a.seatId !== seatToRemove.seatId);
    setSeatAssignments(updatedAssignments);

    const nextQty = quantities[code] - 1;
    const nextQuantities = { ...quantities, [code]: nextQty };
    setQuantities(nextQuantities);

    setDecreaseConfirmTarget(null);
    showToast(`Đã giảm vé và bỏ ghế ${seatToRemove.seatLabel}`, 'info');

    // Recheck active type
    const nextType = findNextIncompleteType(updatedAssignments, nextQuantities);
    setActiveTicketType(nextType);
  };

  // Handle User Clicking a Ticket Card to Activate it
  const handleSelectActiveTicketType = (code: TicketTypeCode) => {
    if (quantities[code] === 0) {
      showToast(`Hãy tăng số lượng vé ${ticketTypeDefinitions.find((t) => t.code === code)?.name} trước khi chọn ghế`, 'warning');
      return;
    }

    setActiveTicketType(code);
    const def = ticketTypeDefinitions.find((t) => t.code === code);
    const remaining = getRemainingCount(code);
    if (remaining > 0) {
      showToast(`Đang chọn ghế cho ${def?.name} — còn ${remaining} ghế`, 'info');
    } else {
      showToast(`${def?.name} đã chọn đủ ${quantities[code]} ghế`, 'info');
    }
  };

  // Handle Seat Click on Seat Map
  const handleSeatClick = (seat: Seat) => {
    if (seat.status === 'occupied') return;

    // Check if seat is already assigned
    const existingAssignment = seatAssignments.find((a) => a.seatId === seat.id);

    if (existingAssignment) {
      // Open action dialog for the assigned seat (allowing removal or ticket type transfer)
      setSeatActionTarget({ seat, assignment: existingAssignment });
      return;
    }

    // Seat is empty: assign it to activeTicketType
    if (totalTicketQuantity === 0) {
      showToast('Vui lòng tăng số lượng vé phía trên trước khi chọn ghế', 'warning');
      return;
    }

    if (!activeTicketType) {
      const nextType = findNextIncompleteType(seatAssignments);
      if (nextType) {
        setActiveTicketType(nextType);
        showToast(`Vui lòng chọn loại vé. Đã kích hoạt vé ${ticketTypeDefinitions.find((t) => t.code === nextType)?.name}`, 'info');
      } else {
        showToast('Bạn đã chọn đủ tất cả các ghế', 'success');
      }
      return;
    }

    // Check if active ticket type still needs seats
    const currentAssignedForActive = getAssignedCount(activeTicketType);
    const targetForActive = quantities[activeTicketType];

    if (currentAssignedForActive >= targetForActive) {
      const activeDef = ticketTypeDefinitions.find((t) => t.code === activeTicketType);
      showToast(`Vé ${activeDef?.name} đã chọn đủ ${targetForActive} ghế`, 'warning');

      // Try auto-switching to another type that needs seats
      const nextType = findNextIncompleteType(seatAssignments);
      if (nextType) {
        setActiveTicketType(nextType);
        const nextDef = ticketTypeDefinitions.find((t) => t.code === nextType);
        showToast(`Chuyển sang chọn ghế cho ${nextDef?.name}`, 'info');
      }
      return;
    }

    // Assign the seat to activeTicketType
    const activeDef = ticketTypeDefinitions.find((t) => t.code === activeTicketType);
    const unitPrice = activeDef?.unitPrice || basePrice;
    const seatSurchargeAmount =
      seat.type === 'vip' ? SEAT_SURCHARGES.vip : seat.type === 'couple' ? SEAT_SURCHARGES.couple : 0;

    const newAssignment: SeatAssignment = {
      seatId: seat.id,
      seatLabel: seat.id,
      ticketTypeId: activeDef?.id || `ticket-${activeTicketType.toLowerCase()}`,
      ticketTypeCode: activeTicketType,
      ticketTypeName: activeDef?.name || 'Người lớn',
      ticketPrice: unitPrice,
      seatSurcharge: seatSurchargeAmount,
      finalPrice: unitPrice + seatSurchargeAmount,
      assignedOrder: Date.now(),
      seatType: seat.type,
    };

    const nextAssignments = [...seatAssignments, newAssignment];
    setSeatAssignments(nextAssignments);

    // Check if active ticket type just completed its quota
    const newAssignedCount = currentAssignedForActive + 1;
    if (newAssignedCount >= targetForActive) {
      // Find next incomplete type
      const nextType = findNextIncompleteType(nextAssignments);
      if (nextType) {
        setActiveTicketType(nextType);
        const nextDef = ticketTypeDefinitions.find((t) => t.code === nextType);
        const remaining = quantities[nextType] - nextAssignments.filter((a) => a.ticketTypeCode === nextType).length;
        showToast(`Đã đủ ghế ${activeDef?.name}. Tiếp theo: chọn ${remaining} ghế ${nextDef?.name}`, 'info');
      } else {
        showToast(`Đã chọn đủ ${nextAssignments.length}/${totalTicketQuantity} ghế!`, 'success');
      }
    }
  };

  // Remove a seat assignment directly
  const handleRemoveSeatAssignment = (seatId: string) => {
    const updated = seatAssignments.filter((a) => a.seatId !== seatId);
    setSeatAssignments(updated);
    setSeatActionTarget(null);

    // Set active type to the type that now has a vacancy
    const removed = seatAssignments.find((a) => a.seatId === seatId);
    if (removed) {
      setActiveTicketType(removed.ticketTypeCode);
      showToast(`Đã bỏ chọn ghế ${seatId}`, 'info');
    }
  };

  // Transfer a seat to another ticket type that has an available slot
  const handleTransferSeatType = (seatId: string, newCode: TicketTypeCode) => {
    const targetSeat = allSeats.find((s) => s.id === seatId);
    const newDef = ticketTypeDefinitions.find((t) => t.code === newCode);
    if (!newDef) return;

    const surchargeAmount =
      targetSeat?.type === 'vip'
        ? SEAT_SURCHARGES.vip
        : targetSeat?.type === 'couple'
        ? SEAT_SURCHARGES.couple
        : 0;

    const updated = seatAssignments.map((a) => {
      if (a.seatId === seatId) {
        return {
          ...a,
          ticketTypeId: newDef.id,
          ticketTypeCode: newCode,
          ticketTypeName: newDef.name,
          ticketPrice: newDef.unitPrice,
          seatSurcharge: surchargeAmount,
          finalPrice: newDef.unitPrice + surchargeAmount,
        };
      }
      return a;
    });

    setSeatAssignments(updated);
    setSeatActionTarget(null);
    showToast(`Đã chuyển ghế ${seatId} sang vé ${newDef.name}`, 'info');

    // Recheck active ticket type
    const nextType = findNextIncompleteType(updated);
    setActiveTicketType(nextType);
  };

  // Confirm and proceed to Concessions
  const handleContinue = () => {
    if (!isAllFullyAssigned) {
      showToast(missingDescription || 'Vui lòng chọn đủ ghế cho từng loại vé', 'warning');
      return;
    }

    // Build structured ticketSelections
    const selections: TicketSelection[] = ticketTypeDefinitions
      .filter((t) => quantities[t.code] > 0)
      .map((t) => {
        const qty = quantities[t.code];
        return {
          ticketTypeId: t.id,
          ticketTypeCode: t.code,
          code: t.code,
          name: t.name,
          ticketTypeName: t.name,
          unitPrice: t.unitPrice,
          quantity: qty,
          subtotal: qty * t.unitPrice,
        };
      });

    // Derive selectedSeats from seatAssignments to maintain strict single source of truth
    const derivedSelectedSeats: Seat[] = seatAssignments.map((assignment) => {
      const match = allSeats.find((s) => s.id === assignment.seatId);
      return (
        match || {
          id: assignment.seatId,
          row: assignment.seatId.charAt(0),
          type: assignment.seatType || 'standard',
          price: assignment.finalPrice,
          status: 'selected',
        }
      );
    });

    const currentConcessions = booking.concessions || booking.selectedConcessions || [];
    const concessionsTotal = currentConcessions.reduce((acc, c) => acc + c.price * c.quantity, 0);

    const subtotal = totalTicketsAndSeatsPrice + concessionsTotal;
    const discount = booking.discount || 0;
    const finalTotal = Math.max(0, subtotal - discount);

    const updatedBooking: BookingState = {
      ...booking,
      cinemaId: CINEMA_CONFIG.id,
      cinemaName: CINEMA_CONFIG.name,
      ticketSelections: selections,
      totalTicketQuantity,
      ticketQuantity: totalTicketQuantity,
      ticketSubtotal,
      seatAssignments,
      selectedSeats: derivedSelectedSeats,
      seatSurcharge,
      concessions: currentConcessions,
      selectedConcessions: currentConcessions,
      subtotal,
      discount,
      total: finalTotal,
      totalPrice: finalTotal,
      grandTotal: finalTotal,
      bookingStatus: 'selecting_concessions',
    };

    onContinue(updatedBooking);
  };

  // Ticket Type Color Tokens
  const getTicketTypeTheme = (code: TicketTypeCode) => {
    switch (code) {
      case 'ADULT':
        return {
          badgeBg: 'bg-[#242014]',
          badgeBorder: 'border-[#4D3D0A]',
          badgeText: 'text-[#F5B800]',
          activeCardBg: 'bg-[#242014]/70 border-[#F5B800]',
          activeBorder: 'border-[#F5B800]',
          seatBg: 'bg-[#F5B800] text-black font-extrabold border-[#F5B800]',
          dotColor: 'bg-[#F5B800]',
          name: 'Người lớn',
        };
      case 'STUDENT':
        return {
          badgeBg: 'bg-[#1e1b4b]/60',
          badgeBorder: 'border-[#4338ca]/60',
          badgeText: 'text-[#a5b4fc]',
          activeCardBg: 'bg-[#1e1b4b]/60 border-[#818cf8]',
          activeBorder: 'border-[#818cf8]',
          seatBg: 'bg-[#6366f1] text-white font-extrabold border-[#818cf8]',
          dotColor: 'bg-[#818cf8]',
          name: 'Sinh viên',
        };
      case 'CHILD':
        return {
          badgeBg: 'bg-[#064e3b]/50',
          badgeBorder: 'border-[#059669]/60',
          badgeText: 'text-[#6ee7b7]',
          activeCardBg: 'bg-[#064e3b]/50 border-[#10b981]',
          activeBorder: 'border-[#10b981]',
          seatBg: 'bg-[#10b981] text-white font-extrabold border-[#34d399]',
          dotColor: 'bg-[#10b981]',
          name: 'Trẻ em',
        };
    }
  };

  return (
    <div className="flex flex-col flex-1 w-full text-[#D4D4D8] min-h-[calc(100dvh-4rem)] bg-[#0E0E0F]">
      {/* 4-Step Booking Progress Indicator: Step 2 active */}
      <div className="shrink-0">
        <BookingProgressBar currentStep="seats" />
      </div>

      {/* Main scrollable content area with enough bottom padding for the fixed footer */}
      <div className="flex-1 w-full pb-48 sm:pb-40">
        {/* 1. Showtime Summary Card */}
        <section className="px-4 py-3 bg-[#171719] border-b border-[#2B2B30]">
          <div className="flex items-center gap-3">
            <img
              src={booking.movie.posterUrl}
              alt={booking.movieTitle || booking.movie.title}
              onError={(e) => handleImageError(e)}
              className="w-14 h-20 rounded-xl object-cover bg-[#202024] shrink-0 border border-[#2B2B30] shadow-sm"
              referrerPolicy="no-referrer"
            />

            <div className="flex flex-col min-w-0 justify-between py-0.5 flex-1">
              <div>
                <div className="flex items-center gap-1.5 mb-1">
                  <span className="px-1.5 py-0.2 rounded bg-[#242014] border border-[#4D3D0A] text-[#F5B800] text-[9px] font-bold">
                    {booking.movie.ageRating}
                  </span>
                  <span className="text-[11px] font-bold text-[#ddb7ff] truncate">
                    {booking.format || booking.selectedSlot?.formatBadge || 'Dolby Atmos'}
                  </span>
                </div>
                <h3 className="font-extrabold text-sm sm:text-base text-white uppercase truncate">
                  {booking.movieTitle || booking.movie.title}
                </h3>
                <p className="text-xs text-[#A1A1AA] truncate mt-0.5">
                  {CINEMA_CONFIG.name} • {booking.room || booking.selectedSlot?.roomName || 'Phòng C'}
                </p>
              </div>

              <div className="text-xs text-[#F5B800] font-semibold mt-1 truncate">
                {booking.time || booking.selectedSlot?.time || '20:30'} •{' '}
                {booking.date || booking.selectedDate || 'Hôm nay, 14/09/2026'}
              </div>
            </div>
          </div>
        </section>

        {/* Floating Toast Notification Banner */}
        {toastMessage && (
          <div className="mx-4 mt-3 p-3 rounded-2xl bg-[#1C1C20] border border-[#3F3F46] flex items-center justify-between gap-2.5 shadow-xl animate-fadeIn">
            <div className="flex items-center gap-2 min-w-0">
              <span
                className={`material-symbols-outlined text-[20px] shrink-0 ${
                  toastMessage.type === 'success'
                    ? 'text-emerald-400'
                    : toastMessage.type === 'warning'
                    ? 'text-[#F5B800]'
                    : 'text-[#818cf8]'
                }`}
              >
                {toastMessage.type === 'success'
                  ? 'check_circle'
                  : toastMessage.type === 'warning'
                  ? 'warning'
                  : 'info'}
              </span>
              <span className="text-xs font-semibold text-white truncate">
                {toastMessage.text}
              </span>
            </div>
            <button
              type="button"
              onClick={() => setToastMessage(null)}
              className="text-[#71717A] hover:text-white p-1"
            >
              <span className="material-symbols-outlined text-[16px]">close</span>
            </button>
          </div>
        )}

        {/* 2. Compact Ticket Selection Cards Area */}
        <section className="px-4 pt-3.5 pb-2">
          <div className="flex items-center justify-between mb-2">
            <span className="text-xs uppercase font-extrabold text-white tracking-wider">
              1. Chọn số lượng vé & loại vé
            </span>
            <span className="text-[11px] font-mono text-[#A1A1AA]">
              {totalAssignedSeats}/{totalTicketQuantity} ghế ({totalTicketQuantity}/{MAX_TICKETS_PER_BOOKING} vé)
            </span>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-3 gap-2.5">
            {ticketTypeDefinitions.map((item) => {
              const qty = quantities[item.code];
              const assigned = getAssignedCount(item.code);
              const isActive = activeTicketType === item.code;
              const theme = getTicketTypeTheme(item.code);
              const hasQty = qty > 0;
              const isTypeComplete = hasQty && assigned === qty;

              return (
                <div
                  key={item.id}
                  onClick={() => handleSelectActiveTicketType(item.code)}
                  className={`p-3 rounded-2xl border transition-all cursor-pointer relative flex flex-col justify-between select-none ${
                    isActive
                      ? `${theme.activeCardBg} shadow-md ring-1 ring-white/10`
                      : hasQty
                      ? 'bg-[#171719] border-[#2B2B30] hover:border-[#3F3F46]'
                      : 'bg-[#121214] border-[#202024] opacity-75 hover:opacity-100'
                  }`}
                >
                  {/* Top Bar: Icon, Name, and Active Indicator */}
                  <div className="flex items-start justify-between gap-2">
                    <div className="flex items-center gap-2 min-w-0">
                      <div
                        className={`w-8 h-8 rounded-lg flex items-center justify-center shrink-0 border ${
                          isActive
                            ? 'bg-white/10 text-white border-white/20'
                            : `${theme.badgeBg} ${theme.badgeText} ${theme.badgeBorder}`
                        }`}
                      >
                        <span className="material-symbols-outlined text-[18px]">{item.icon}</span>
                      </div>

                      <div className="flex flex-col min-w-0">
                        <div className="flex items-center gap-1">
                          <span className="font-extrabold text-sm text-white truncate">
                            {item.name}
                          </span>
                          {item.requiresVerification && (
                            <button
                              type="button"
                              onClick={(e) => {
                                e.stopPropagation();
                                setActivePolicyModal(item);
                              }}
                              className="text-[#A1A1AA] hover:text-[#F5B800] p-0.5 rounded"
                              title="Xem điều kiện"
                            >
                              <span className="material-symbols-outlined text-[14px]">info</span>
                            </button>
                          )}
                        </div>
                        <span className="text-xs font-bold text-[#F5B800]">
                          {formatCurrency(item.unitPrice)}
                        </span>
                      </div>
                    </div>

                    {/* Active Selection Badge */}
                    {isActive ? (
                      <span className="px-2 py-0.5 rounded-full bg-white text-black text-[10px] font-black uppercase tracking-wider shrink-0 flex items-center gap-1 shadow-sm">
                        <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
                        Đang chọn
                      </span>
                    ) : isTypeComplete ? (
                      <span className="px-1.5 py-0.5 rounded-full bg-emerald-500/20 text-emerald-400 text-[10px] font-bold shrink-0 flex items-center gap-0.5 border border-emerald-500/30">
                        <span className="material-symbols-outlined text-[12px]">check</span>
                        Đủ ghế
                      </span>
                    ) : null}
                  </div>

                  {/* Bottom Bar: Stepper Controls and Assigned Seat Count */}
                  <div className="flex items-center justify-between mt-3 pt-2.5 border-t border-[#2B2B30]/60">
                    <span className="text-[11px] text-[#A1A1AA] font-medium">
                      {hasQty ? (
                        <span className={isTypeComplete ? 'text-emerald-400 font-bold' : 'text-[#D4D4D8]'}>
                          Đã chọn {assigned}/{qty} ghế
                        </span>
                      ) : (
                        <span className="text-[#71717A]">Chưa có vé</span>
                      )}
                    </span>

                    {/* Counter Buttons (Min 44x44px touch target) */}
                    <div
                      className="flex items-center gap-1.5 bg-[#0E0E0F] p-0.5 rounded-xl border border-[#2B2B30]"
                      onClick={(e) => e.stopPropagation()}
                    >
                      <button
                        type="button"
                        aria-label={`Giảm vé ${item.name}`}
                        disabled={qty <= 0}
                        onClick={() => handleDecreaseQuantity(item.code)}
                        className={`w-9 h-9 min-w-[36px] min-h-[36px] rounded-lg flex items-center justify-center transition-all select-none ${
                          qty > 0
                            ? 'bg-[#1C1C20] hover:bg-[#2B2B30] text-white active:scale-95 cursor-pointer'
                            : 'bg-transparent text-[#52525B] cursor-not-allowed'
                        }`}
                      >
                        <span className="material-symbols-outlined text-[18px]">remove</span>
                      </button>

                      <span
                        className={`w-6 text-center font-extrabold text-sm select-none ${
                          qty > 0 ? 'text-[#F5B800]' : 'text-[#71717A]'
                        }`}
                      >
                        {qty}
                      </span>

                      <button
                        type="button"
                        aria-label={`Tăng vé ${item.name}`}
                        disabled={isMaxReached}
                        onClick={() => handleIncreaseQuantity(item.code)}
                        className={`w-9 h-9 min-w-[36px] min-h-[36px] rounded-lg flex items-center justify-center transition-all select-none ${
                          !isMaxReached
                            ? 'bg-[#1C1C20] hover:bg-[#2B2B30] text-[#F5B800] active:scale-95 cursor-pointer'
                            : 'bg-transparent text-[#52525B] cursor-not-allowed'
                        }`}
                      >
                        <span className="material-symbols-outlined text-[18px]">add</span>
                      </button>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        </section>

        {/* 3. Active Ticket Type Guidance Bar (Sticky directly above seat map) */}
        <section className="px-4 py-2 mt-1">
          <div
            className={`p-3 rounded-2xl border transition-all flex flex-col sm:flex-row sm:items-center justify-between gap-2.5 ${
              isAllFullyAssigned
                ? 'bg-emerald-500/10 border-emerald-500/30'
                : activeTicketType
                ? `${getTicketTypeTheme(activeTicketType).badgeBg} ${getTicketTypeTheme(activeTicketType).badgeBorder}`
                : 'bg-[#171719] border-[#2B2B30]'
            }`}
          >
            <div className="flex items-center gap-2.5 min-w-0">
              <div
                className={`w-8 h-8 rounded-full flex items-center justify-center shrink-0 ${
                  isAllFullyAssigned
                    ? 'bg-emerald-500 text-black font-black'
                    : activeTicketType
                    ? `${getTicketTypeTheme(activeTicketType).dotColor} text-black font-black`
                    : 'bg-[#2B2B30] text-[#A1A1AA]'
                }`}
              >
                <span className="material-symbols-outlined text-[18px]">
                  {isAllFullyAssigned ? 'check' : 'event_seat'}
                </span>
              </div>

              <div className="flex flex-col min-w-0">
                {isAllFullyAssigned ? (
                  <>
                    <span className="font-extrabold text-sm text-emerald-400">
                      Đã chọn đủ {totalAssignedSeats}/{totalTicketQuantity} ghế!
                    </span>
                    <span className="text-[11px] text-[#A1A1AA]">
                      Tất cả các loại vé đã được gắn ghế đầy đủ. Bạn có thể tiếp tục.
                    </span>
                  </>
                ) : activeTicketType ? (
                  <>
                    <div className="flex items-center gap-2">
                      <span className="text-xs text-[#A1A1AA]">Đang chọn ghế cho:</span>
                      <span className="font-extrabold text-sm text-white">
                        Vé {getTicketTypeTheme(activeTicketType).name}
                      </span>
                    </div>
                    <span className="text-[11px] font-semibold text-[#D4D4D8] mt-0.5">
                      Đã chọn {getAssignedCount(activeTicketType)}/{quantities[activeTicketType]} ghế · Còn{' '}
                      {getRemainingCount(activeTicketType)} ghế
                    </span>
                  </>
                ) : (
                  <>
                    <span className="font-bold text-xs text-white">
                      Chọn một loại vé phía trên trước khi chọn ghế
                    </span>
                    <span className="text-[11px] text-[#71717A]">
                      Chạm vào card loại vé để bắt đầu xếp ghế
                    </span>
                  </>
                )}
              </div>
            </div>

            {/* Quick Helper pill */}
            {!isAllFullyAssigned && activeTicketType && (
              <span className="text-[11px] text-[#A1A1AA] self-end sm:self-center font-medium bg-black/40 px-2.5 py-1 rounded-lg">
                Chạm ghế trống bên dưới để gán
              </span>
            )}
          </div>
        </section>

        {/* 4. 3D Curved Cinema Screen Graphic */}
        <div className="px-4 pt-3 pb-2 flex flex-col items-center overflow-hidden">
          <div className="relative w-full max-w-sm flex flex-col items-center">
            <div className="w-full h-8 bg-gradient-to-b from-white/15 via-white/5 to-transparent blur-md rounded-t-full pointer-events-none" />
            <svg className="w-full h-6 -mt-4" viewBox="0 0 320 28" fill="none">
              <path
                d="M 10 24 Q 160 6 310 24"
                stroke="url(#screenGrad2)"
                strokeWidth="4"
                strokeLinecap="round"
              />
              <defs>
                <linearGradient id="screenGrad2" x1="0%" y1="0%" x2="100%" y2="0%">
                  <stop offset="0%" stopColor="#2B2B30" />
                  <stop offset="50%" stopColor="#71717A" />
                  <stop offset="100%" stopColor="#2B2B30" />
                </linearGradient>
              </defs>
            </svg>
            <span className="text-[10px] font-bold text-[#71717A] tracking-[0.25em] -mt-1 uppercase">
              Màn hình chiếu
            </span>
          </div>
        </div>

        {/* 5. Seat Layout Matrix */}
        <section className="w-full overflow-x-auto scrollbar-none px-2 py-2 flex flex-col items-center select-none">
          <div className="flex flex-col items-center gap-2.5 min-w-[320px]">
            {rows.map((row) => {
              const rowSeats = allSeats.filter((s) => s.row === row);
              const isCoupleRow = row === 'E';

              return (
                <div key={row} className="flex items-center gap-2">
                  <span className="w-5 text-center text-xs font-bold text-[#A1A1AA]">{row}</span>

                  <div className="flex items-center gap-1.5 sm:gap-2">
                    {rowSeats.map((seat) => {
                      const isOccupied = seat.status === 'occupied';
                      const assignment = seatAssignments.find((a) => a.seatId === seat.id);
                      const isAssigned = Boolean(assignment);

                      let seatClasses = '';
                      let accessibleLabel = `Ghế ${seat.id}`;

                      if (isOccupied) {
                        seatClasses = 'bg-[#131315] text-[#52525B] border border-[#202024] cursor-not-allowed';
                        accessibleLabel = `Ghế ${seat.id}, đã bán`;
                      } else if (isAssigned && assignment) {
                        const theme = getTicketTypeTheme(assignment.ticketTypeCode);
                        seatClasses = `${theme.seatBg} shadow-sm active:scale-95 cursor-pointer animate-scaleUp`;
                        accessibleLabel = `Ghế ${seat.id}, vé ${assignment.ticketTypeName}, đang được chọn`;
                      } else {
                        // Available seat based on tier
                        if (seat.type === 'vip') {
                          seatClasses =
                            'bg-[#202024] text-[#F5B800] border border-[#F5B800]/50 hover:border-[#F5B800] cursor-pointer';
                          accessibleLabel = `Ghế ${seat.id}, hạng VIP, phụ thu 20.000đ, còn trống`;
                        } else if (isCoupleRow) {
                          seatClasses =
                            'bg-[#6f00be]/30 text-[#ddb7ff] border border-[#6f00be] hover:border-[#a855f7] cursor-pointer';
                          accessibleLabel = `Ghế ${seat.id}, ghế Đôi, phụ thu 60.000đ, còn trống`;
                        } else {
                          seatClasses =
                            'bg-[#171719] text-[#D4D4D8] border border-[#2B2B30] hover:border-[#71717A] cursor-pointer';
                          accessibleLabel = `Ghế ${seat.id}, hạng thường, còn trống`;
                        }
                      }

                      return (
                        <button
                          key={seat.id}
                          type="button"
                          aria-label={accessibleLabel}
                          disabled={isOccupied}
                          onClick={() => handleSeatClick(seat)}
                          className={`${
                            isCoupleRow ? 'w-16 sm:w-20' : 'w-8 sm:w-9'
                          } h-8 sm:h-9 rounded-lg flex items-center justify-center text-xs font-bold transition-all relative ${seatClasses}`}
                        >
                          {isOccupied ? (
                            <span className="text-[10px] text-[#52525B]">✕</span>
                          ) : isAssigned && assignment ? (
                            <div className="flex flex-col items-center leading-none">
                              <span className="text-[11px] font-black">{seat.id}</span>
                              <span className="text-[8px] opacity-90 font-medium">
                                {assignment.ticketTypeCode === 'ADULT'
                                  ? 'NL'
                                  : assignment.ticketTypeCode === 'STUDENT'
                                  ? 'SV'
                                  : 'TE'}
                              </span>
                            </div>
                          ) : (
                            <span>{seat.col}</span>
                          )}
                        </button>
                      );
                    })}
                  </div>

                  <span className="w-5 text-center text-xs font-bold text-[#A1A1AA]">{row}</span>
                </div>
              );
            })}
          </div>
        </section>

        {/* 6. Seat Status & Ticket Type Legend */}
        <section className="px-4 py-2 mt-1">
          <div className="p-3 rounded-2xl bg-[#171719] border border-[#2B2B30] flex flex-col gap-2.5 text-xs text-[#A1A1AA]">
            {/* Ticket type assigned legend */}
            <div className="flex items-center justify-center flex-wrap gap-3 pb-2 border-b border-[#2B2B30]/70">
              <div className="flex items-center gap-1.5">
                <span className="w-3.5 h-3.5 rounded bg-[#F5B800] border border-[#F5B800]" />
                <span className="text-white font-medium">Vé Người lớn</span>
              </div>
              <div className="flex items-center gap-1.5">
                <span className="w-3.5 h-3.5 rounded bg-[#6366f1] border border-[#818cf8]" />
                <span className="text-white font-medium">Vé Sinh viên</span>
              </div>
              <div className="flex items-center gap-1.5">
                <span className="w-3.5 h-3.5 rounded bg-[#10b981] border border-[#34d399]" />
                <span className="text-white font-medium">Vé Trẻ em</span>
              </div>
            </div>

            {/* Seat tiers and occupied status legend */}
            <div className="flex items-center justify-center flex-wrap gap-3 text-[11px]">
              <div className="flex items-center gap-1.5">
                <span className="w-3.5 h-3.5 rounded bg-[#171719] border border-[#2B2B30]" />
                <span>Thường (0đ)</span>
              </div>
              <div className="flex items-center gap-1.5">
                <span className="w-3.5 h-3.5 rounded bg-[#202024] border border-[#F5B800]/60" />
                <span className="text-[#F5B800]">VIP (+20.000đ)</span>
              </div>
              <div className="flex items-center gap-1.5">
                <span className="w-6 h-3.5 rounded bg-[#6f00be]/30 border border-[#6f00be]" />
                <span className="text-[#ddb7ff]">Đôi (+60.000đ)</span>
              </div>
              <div className="flex items-center gap-1.5">
                <span className="w-3.5 h-3.5 rounded bg-[#131315] border border-[#202024] flex items-center justify-center text-[9px] text-[#52525B]">
                  ✕
                </span>
                <span>Đã bán</span>
              </div>
            </div>
          </div>
        </section>

        {/* 7. Assigned Seats Grouped by Ticket Type */}
        <section className="px-4 py-2">
          <div className="flex items-center justify-between mb-2">
            <span className="text-xs uppercase font-extrabold text-white tracking-wider">
              2. Danh sách ghế đã gán theo loại vé
            </span>
            <span className="text-[11px] text-[#71717A]">
              Chạm nhóm để đổi loại đang chọn
            </span>
          </div>

          <div className="flex flex-col gap-2">
            {(['ADULT', 'STUDENT', 'CHILD'] as TicketTypeCode[]).map((code) => {
              const qty = quantities[code];
              if (qty === 0) return null;

              const def = ticketTypeDefinitions.find((t) => t.code === code);
              const theme = getTicketTypeTheme(code);
              const assignedSeatsForType = seatAssignments.filter((a) => a.ticketTypeCode === code);
              const assignedCount = assignedSeatsForType.length;
              const isComplete = assignedCount === qty;
              const isSelected = activeTicketType === code;

              // Calculate total for this group
              const groupBaseSubtotal = qty * (def?.unitPrice || basePrice);
              const groupSurcharges = assignedSeatsForType.reduce((acc, a) => acc + a.seatSurcharge, 0);

              return (
                <div
                  key={code}
                  onClick={() => handleSelectActiveTicketType(code)}
                  className={`p-3 rounded-2xl border transition-all cursor-pointer flex flex-col sm:flex-row sm:items-center justify-between gap-2.5 ${
                    isSelected
                      ? `${theme.activeCardBg}`
                      : 'bg-[#171719] border-[#2B2B30] hover:border-[#3F3F46]'
                  }`}
                >
                  <div className="flex items-center gap-2.5 min-w-0">
                    <span className={`w-3 h-3 rounded-full shrink-0 ${theme.dotColor}`} />
                    <div className="flex flex-col min-w-0">
                      <div className="flex items-center gap-2 flex-wrap">
                        <span className="font-extrabold text-sm text-white">
                          Vé {def?.name} ({assignedCount}/{qty})
                        </span>
                        {isComplete ? (
                          <span className="px-1.5 py-0.2 rounded bg-emerald-500/20 text-emerald-400 text-[10px] font-bold border border-emerald-500/30">
                            Đã đủ ghế
                          </span>
                        ) : (
                          <span className="px-1.5 py-0.2 rounded bg-[#242014] text-[#F5B800] text-[10px] font-bold border border-[#4D3D0A]">
                            Còn thiếu {qty - assignedCount} ghế
                          </span>
                        )}
                      </div>

                      {/* Seats List for this ticket type */}
                      <div className="flex items-center gap-1.5 flex-wrap mt-1">
                        {assignedCount > 0 ? (
                          assignedSeatsForType.map((seatItem) => (
                            <span
                              key={seatItem.seatId}
                              onClick={(e) => {
                                e.stopPropagation();
                                const fullSeat = allSeats.find((s) => s.id === seatItem.seatId);
                                if (fullSeat) {
                                  setSeatActionTarget({ seat: fullSeat, assignment: seatItem });
                                }
                              }}
                              className={`px-2 py-0.5 rounded-lg text-xs font-bold border ${theme.badgeBg} ${theme.badgeText} ${theme.badgeBorder} flex items-center gap-1 hover:brightness-125 cursor-pointer`}
                              title="Bấm để bỏ hoặc chuyển loại vé"
                            >
                              <span>{seatItem.seatLabel}</span>
                              {seatItem.seatSurcharge > 0 && (
                                <span className="text-[9px] opacity-75">
                                  (+{formatCurrency(seatItem.seatSurcharge)})
                                </span>
                              )}
                              <span className="material-symbols-outlined text-[12px] opacity-60">edit</span>
                            </span>
                          ))
                        ) : (
                          <span className="text-xs text-[#71717A] italic">
                            Chưa chọn ghế nào cho loại vé này
                          </span>
                        )}
                      </div>
                    </div>
                  </div>

                  {/* Financial subtotal for this group */}
                  <div className="flex sm:flex-col items-baseline sm:items-end justify-between sm:justify-center border-t sm:border-t-0 border-[#2B2B30]/50 pt-1.5 sm:pt-0 shrink-0">
                    <span className="text-[10px] text-[#A1A1AA] sm:text-right">Tạm tính:</span>
                    <span className="text-sm font-extrabold text-white">
                      {formatCurrency(groupBaseSubtotal + groupSurcharges)}
                    </span>
                  </div>
                </div>
              );
            })}
          </div>
        </section>
      </div>

      {/* Seat Action Modal (Bottom Sheet / Dialog when tapping an already assigned seat) */}
      {seatActionTarget && (
        <div
          role="dialog"
          aria-modal="true"
          className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm animate-fadeIn"
          onClick={() => setSeatActionTarget(null)}
        >
          <div
            className="w-full max-w-sm bg-[#171719] border border-[#2B2B30] rounded-3xl p-5 shadow-2xl flex flex-col gap-4 animate-scaleUp"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-center justify-between pb-3 border-b border-[#2B2B30]">
              <div className="flex items-center gap-2">
                <div
                  className={`w-9 h-9 rounded-xl flex items-center justify-center ${
                    getTicketTypeTheme(seatActionTarget.assignment.ticketTypeCode).badgeBg
                  } ${getTicketTypeTheme(seatActionTarget.assignment.ticketTypeCode).badgeText} border ${
                    getTicketTypeTheme(seatActionTarget.assignment.ticketTypeCode).badgeBorder
                  }`}
                >
                  <span className="font-extrabold text-sm">{seatActionTarget.seat.id}</span>
                </div>
                <div>
                  <h4 className="font-extrabold text-sm text-white">
                    Ghế {seatActionTarget.seat.id} — Vé {seatActionTarget.assignment.ticketTypeName}
                  </h4>
                  <span className="text-[11px] text-[#A1A1AA]">
                    Giá: {formatCurrency(seatActionTarget.assignment.finalPrice)}
                    {seatActionTarget.assignment.seatSurcharge > 0 &&
                      ` (gồm phụ thu +${formatCurrency(seatActionTarget.assignment.seatSurcharge)})`}
                  </span>
                </div>
              </div>
              <button
                type="button"
                aria-label="Đóng"
                onClick={() => setSeatActionTarget(null)}
                className="w-8 h-8 rounded-full bg-[#202024] hover:bg-[#2B2B30] text-[#A1A1AA] hover:text-white flex items-center justify-center transition-colors"
              >
                <span className="material-symbols-outlined text-[18px]">close</span>
              </button>
            </div>

            <div className="flex flex-col gap-2">
              <span className="text-xs text-[#A1A1AA] font-medium">Lựa chọn thao tác cho ghế này:</span>

              {/* Option: Transfer to another ticket type that has available slots */}
              {(['ADULT', 'STUDENT', 'CHILD'] as TicketTypeCode[])
                .filter((code) => code !== seatActionTarget.assignment.ticketTypeCode && getRemainingCount(code) > 0)
                .map((code) => {
                  const def = ticketTypeDefinitions.find((t) => t.code === code);
                  const theme = getTicketTypeTheme(code);
                  return (
                    <button
                      key={code}
                      type="button"
                      onClick={() => handleTransferSeatType(seatActionTarget.seat.id, code)}
                      className={`w-full py-2.5 px-3 rounded-xl border text-xs font-bold flex items-center justify-between transition-colors ${theme.badgeBg} ${theme.badgeText} ${theme.badgeBorder} hover:brightness-125`}
                    >
                      <div className="flex items-center gap-2">
                        <span className={`w-2.5 h-2.5 rounded-full ${theme.dotColor}`} />
                        <span>Chuyển sang vé {def?.name}</span>
                      </div>
                      <span className="text-[11px] opacity-75">
                        Còn {getRemainingCount(code)} slot
                      </span>
                    </button>
                  );
                })}

              {/* Option: Unassign / Drop this seat */}
              <button
                type="button"
                onClick={() => handleRemoveSeatAssignment(seatActionTarget.seat.id)}
                className="w-full py-2.5 px-3 rounded-xl bg-rose-500/10 hover:bg-rose-500/20 text-rose-400 border border-rose-500/30 text-xs font-bold flex items-center justify-center gap-1.5 transition-colors"
              >
                <span className="material-symbols-outlined text-[16px]">delete</span>
                <span>Bỏ chọn ghế này</span>
              </button>

              <button
                type="button"
                onClick={() => setSeatActionTarget(null)}
                className="w-full py-2.5 px-3 rounded-xl bg-[#202024] hover:bg-[#2B2B30] text-[#D4D4D8] text-xs font-bold transition-colors mt-1"
              >
                Giữ nguyên
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Confirmation Dialog on Quantity Decrease with Seat Removal */}
      {decreaseConfirmTarget && (
        <div
          role="dialog"
          aria-modal="true"
          className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm animate-fadeIn"
        >
          <div className="w-full max-w-sm bg-[#171719] border border-[#2B2B30] rounded-3xl p-5 shadow-2xl flex flex-col gap-4 animate-scaleUp">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-[#242014] border border-[#4D3D0A] flex items-center justify-center text-[#F5B800] shrink-0">
                <span className="material-symbols-outlined text-[22px]">warning</span>
              </div>
              <div className="flex flex-col min-w-0">
                <h4 className="font-extrabold text-sm text-white">Xác nhận giảm số lượng</h4>
                <span className="text-xs text-[#A1A1AA]">
                  Ghế đã chọn vượt quá số lượng vé mới
                </span>
              </div>
            </div>

            <p className="text-xs text-[#D4D4D8] leading-relaxed">
              Giảm vé <strong>{decreaseConfirmTarget.name}</strong> từ{' '}
              {quantities[decreaseConfirmTarget.code]} xuống{' '}
              {quantities[decreaseConfirmTarget.code] - 1} sẽ bỏ ghế{' '}
              <strong className="text-[#F5B800]">
                {decreaseConfirmTarget.seatToRemove.seatLabel}
              </strong>
              . Bạn có muốn tiếp tục?
            </p>

            <div className="grid grid-cols-2 gap-2 pt-1">
              <button
                type="button"
                onClick={() => setDecreaseConfirmTarget(null)}
                className="h-11 rounded-xl bg-[#202024] hover:bg-[#2B2B30] text-white text-xs font-bold border border-[#2B2B30] transition-colors"
              >
                Giữ nguyên
              </button>

              <button
                type="button"
                onClick={handleConfirmDecreaseWithSeatDrop}
                className="h-11 rounded-xl bg-[#F5B800] hover:bg-[#E6AA00] text-black text-xs font-bold transition-colors shadow-sm"
              >
                Giảm & Bỏ ghế
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Ticket Policy Condition Modal */}
      {activePolicyModal && (
        <div
          role="dialog"
          aria-modal="true"
          className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm animate-fadeIn"
          onClick={() => setActivePolicyModal(null)}
        >
          <div
            className="w-full max-w-sm bg-[#171719] border border-[#2B2B30] rounded-3xl p-5 shadow-2xl flex flex-col gap-4 animate-scaleUp"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-center justify-between pb-3 border-b border-[#2B2B30]">
              <div className="flex items-center gap-2.5">
                <div className="w-8 h-8 rounded-lg bg-[#242014] border border-[#4D3D0A] flex items-center justify-center text-[#F5B800]">
                  <span className="material-symbols-outlined text-[18px]">
                    {activePolicyModal.icon}
                  </span>
                </div>
                <div>
                  <h4 className="font-extrabold text-sm text-white">
                    Điều kiện: Vé {activePolicyModal.name}
                  </h4>
                  <span className="text-[10px] text-[#A1A1AA]">Quy định tại CineAI Central</span>
                </div>
              </div>
              <button
                type="button"
                aria-label="Đóng"
                onClick={() => setActivePolicyModal(null)}
                className="w-8 h-8 rounded-full bg-[#202024] hover:bg-[#2B2B30] text-[#A1A1AA] hover:text-white flex items-center justify-center transition-colors border border-[#2B2B30]"
              >
                <span className="material-symbols-outlined text-[18px]">close</span>
              </button>
            </div>

            <div className="text-xs text-[#D4D4D8] leading-relaxed space-y-2.5">
              <p>{activePolicyModal.policyDescription}</p>

              <div className="p-3 rounded-xl bg-[#202024] border border-[#2B2B30] flex items-start gap-2 text-[11px] text-[#A1A1AA]">
                <span className="material-symbols-outlined text-[16px] text-[#F5B800] shrink-0 mt-0.5">
                  verified
                </span>
                <span>
                  Vui lòng chuẩn bị sẵn giấy tờ chứng minh khi tới quầy soát vé để nhân viên hỗ trợ nhanh nhất.
                </span>
              </div>
            </div>

            <button
              type="button"
              onClick={() => setActivePolicyModal(null)}
              className="w-full h-11 rounded-xl bg-[#F5B800] hover:bg-[#E6AA00] text-black font-extrabold text-xs transition-colors cursor-pointer"
            >
              Đã hiểu & Quay lại
            </button>
          </div>
        </div>
      )}

      {/* 8. Fixed Bottom Booking Action Bar (Fully opaque, never covered by bottom nav) */}
      <footer
        className="fixed bottom-0 left-0 right-0 z-40 bg-[#121214] border-t border-[#2B2B30] px-4 pt-3.5 shadow-[0_-4px_24px_rgba(0,0,0,0.9)] pointer-events-auto"
        style={{ paddingBottom: 'max(14px, calc(14px + env(safe-area-inset-bottom, 0px)))' }}
      >
        <div className="w-full max-w-md mx-auto flex flex-col min-[390px]:flex-row min-[390px]:items-center justify-between gap-3">
          {/* Left Info: Status, missing description, and total price */}
          <div className="flex flex-col min-w-0 flex-1">
            <div className="flex items-center gap-1.5 flex-wrap">
              <span className="text-xs uppercase font-extrabold text-white tracking-wider">
                Đã chọn: {totalAssignedSeats}/{totalTicketQuantity} ghế
              </span>
              {seatSurcharge > 0 && (
                <span className="text-[11px] text-[#F5B800] font-bold">
                  (Phụ thu: +{formatCurrency(seatSurcharge)})
                </span>
              )}
            </div>

            {/* If missing, display specific missing tickets; otherwise show assigned list */}
            {missingDescription ? (
              <span className="text-xs font-semibold text-[#F5B800] truncate mt-0.5">
                {missingDescription}
              </span>
            ) : totalAssignedSeats > 0 ? (
              <span className="text-xs text-emerald-400 font-semibold truncate mt-0.5">
                Đã đủ ghế: {seatAssignments.map((a) => a.seatLabel).join(', ')}
              </span>
            ) : (
              <span className="text-xs text-[#71717A] truncate mt-0.5">
                Vui lòng chọn loại vé và chọn ghế
              </span>
            )}

            <div className="flex items-baseline gap-1.5 mt-0.5">
              <span className="text-base sm:text-lg font-black text-[#F5B800]">
                {formatCurrency(totalTicketsAndSeatsPrice)}
              </span>
              {seatSurcharge > 0 && (
                <span className="text-[10px] text-[#71717A]">
                  (Gốc: {formatCurrency(ticketSubtotal)})
                </span>
              )}
            </div>
          </div>

          {/* Right Action Button: "Tiếp tục: Bắp nước" */}
          <button
            type="button"
            onClick={handleContinue}
            disabled={!isAllFullyAssigned}
            className={`w-full min-[390px]:w-auto min-[390px]:min-w-[170px] h-[48px] rounded-xl text-xs sm:text-sm font-bold flex items-center justify-center gap-1.5 transition-all select-none ${
              isAllFullyAssigned
                ? 'bg-[#F5B800] hover:bg-[#E6AA00] text-black active:scale-[0.98] cursor-pointer shadow-md'
                : 'bg-[#202024] text-[#71717A] cursor-not-allowed shadow-none border border-[#2B2B30]'
            }`}
          >
            <span>
              {isAllFullyAssigned
                ? 'Tiếp tục: Bắp nước'
                : totalTicketQuantity === 0
                ? 'Chọn vé để tiếp tục'
                : `Còn thiếu ${totalTicketQuantity - totalAssignedSeats} ghế`}
            </span>
            <span className="material-symbols-outlined text-[18px]">arrow_forward</span>
          </button>
        </div>
      </footer>
    </div>
  );
};
