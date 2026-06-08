import logoUrl from '../assets/logo-mark.svg';

interface LogoProps {
  size?: number;
  className?: string;
}

export function Logo({ size = 40, className }: LogoProps) {
  return (
    <img
      src={logoUrl}
      width={size}
      height={size}
      alt="macleanup"
      className={className}
      style={{ borderRadius: size * 0.22 }}
    />
  );
}
