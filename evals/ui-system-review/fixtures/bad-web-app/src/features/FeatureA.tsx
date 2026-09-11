import Button from '@mui/material/Button';
import HomeIcon from '@mui/icons-material/Home';
import { HomeIcon as HeroHome } from '@heroicons/react/24/solid';

export function FeatureA() {
  return (
    <div style={{ padding: '13px', backgroundColor: '#3B82F6', color: '#fff' }}>
      <Button variant="contained">Save</Button>
      <HomeIcon />
      <HeroHome width={20} />
    </div>
  );
}
