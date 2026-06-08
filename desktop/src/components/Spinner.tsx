interface SpinnerProps {
  size?: number;
}

export function Spinner({ size = 20 }: SpinnerProps) {
  return (
    <div
      className="splash-spinner"
      style={{ width: size, height: size }}
      role="status"
      aria-label="Loading"
    />
  );
}
