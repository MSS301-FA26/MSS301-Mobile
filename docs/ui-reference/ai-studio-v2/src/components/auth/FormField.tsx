import React from 'react';

interface FormFieldProps {
  id: string;
  label: string;
  type?: string;
  value: string;
  onChange: (e: React.ChangeEvent<HTMLInputElement>) => void;
  placeholder?: string;
  icon?: string;
  error?: string;
  helperText?: string;
  optional?: boolean;
  autoComplete?: string;
  className?: string;
  rightElement?: React.ReactNode;
}

export const FormField: React.FC<FormFieldProps> = ({
  id,
  label,
  type = 'text',
  value,
  onChange,
  placeholder,
  icon,
  error,
  helperText,
  optional = false,
  autoComplete,
  className = '',
  rightElement,
}) => {
  return (
    <div className={`flex flex-col gap-1.5 ${className}`}>
      {/* Label & Optional badge */}
      <div className="flex items-center justify-between">
        <label htmlFor={id} className="text-xs font-semibold text-[#e5e2e1]">
          {label} {!optional && <span className="text-rose-400">*</span>}
        </label>
        {optional && (
          <span className="text-[11px] text-[#9c8f79] font-normal">
            Không bắt buộc
          </span>
        )}
      </div>

      {/* Input container */}
      <div className="relative">
        {icon && (
          <span className="material-symbols-outlined absolute left-3.5 top-1/2 -translate-y-1/2 text-[#9c8f79] text-[20px] pointer-events-none select-none">
            {icon}
          </span>
        )}
        <input
          id={id}
          type={type}
          value={value}
          onChange={onChange}
          placeholder={placeholder}
          autoComplete={autoComplete}
          className={`w-full h-12 bg-[#0E0E0F] border rounded-xl ${
            icon ? 'pl-11' : 'pl-4'
          } ${rightElement ? 'pr-12' : 'pr-4'} text-sm text-white placeholder-[#71717A] transition-all focus:outline-none ${
            error
              ? 'border-rose-500/80 focus:border-rose-500 focus:ring-1 focus:ring-rose-500/40'
              : 'border-[#2B2B30] focus:border-[#F5B800] focus:ring-1 focus:ring-[#F5B800]/20'
          }`}
        />
        {rightElement && (
          <div className="absolute right-1 top-1/2 -translate-y-1/2 flex items-center">
            {rightElement}
          </div>
        )}
      </div>

      {/* Helper text or Error message */}
      {error ? (
        <span className="text-[11px] text-rose-400 font-medium pl-0.5">
          {error}
        </span>
      ) : helperText ? (
        <span className="text-[11px] text-[#9c8f79] pl-0.5 leading-tight">
          {helperText}
        </span>
      ) : null}
    </div>
  );
};
