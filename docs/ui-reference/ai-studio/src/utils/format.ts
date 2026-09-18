import React from 'react';

/**
 * Utility functions for formatting currency and handling image fallbacks
 */

export function formatCurrency(amount: number): string {
  return `${Math.round(amount).toLocaleString('vi-VN')} ₫`;
}

export const FALLBACK_MOVIE_POSTER =
  'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=800&auto=format&fit=crop&q=80';

export const FALLBACK_MOVIE_BANNER =
  'https://images.unsplash.com/photo-1517604931442-7e0c8ed2963c?w=1200&auto=format&fit=crop&q=80';

export const FALLBACK_CONCESSION_IMAGE =
  'https://images.unsplash.com/photo-1585647347483-22b66260dfff?w=600&auto=format&fit=crop&q=80';

export function handleImageError(
  e: React.SyntheticEvent<HTMLImageElement, Event>,
  fallbackUrl: string = FALLBACK_MOVIE_POSTER
) {
  const target = e.currentTarget;
  if (target.src !== fallbackUrl) {
    target.onerror = null;
    target.src = fallbackUrl;
  }
}
