import { Button } from '@chakra-ui/react';
import { Save } from 'lucide-react';

export function FeatureB() {
  return (
    <div style={{ margin: '7px', border: '1px solid #ccc' }}>
      <Button colorScheme="blue">Save</Button>
      <Save size={18} />
      <div onClick={() => alert('ok')} style={{ cursor: 'pointer', color: '#ef4444' }}>
        Delete
      </div>
    </div>
  );
}
