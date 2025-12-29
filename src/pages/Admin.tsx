import { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '@/hooks/useAuth';
import { useDogs } from '@/hooks/useDogs';
import { useRescues } from '@/hooks/useRescues';
import { supabase } from '@/integrations/supabase/client';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle, AlertDialogTrigger } from '@/components/ui/alert-dialog';
import { Checkbox } from '@/components/ui/checkbox';
import { Heart, Loader2, Plus, Pencil, Trash2, LogOut, ArrowLeft, Upload, X } from 'lucide-react';
import { useToast } from '@/hooks/use-toast';
import { useQueryClient } from '@tanstack/react-query';
import { BreedCombobox } from '@/components/BreedCombobox';
import { RescueCombobox } from '@/components/RescueCombobox';
import { LocationCombobox } from '@/components/LocationCombobox';
import type { Dog } from '@/types/dog';
import { DevBypassBanner } from '@/components/auth/DevBypassBanner';
import { DEFAULT_DOG_IMAGE } from '@/lib/constants';

interface DogFormData {
  name: string;
  breeds: string[];
  age: string;
  size: string;
  gender: string;
  location: string;
  rescue_id: string;
  image: string;
  description: string;
  good_with_kids: boolean;
  good_with_dogs: boolean;
  good_with_cats: boolean;
}

const initialFormData: DogFormData = {
  name: '',
  breeds: [],
  age: 'Adult',
  size: 'Medium',
  gender: 'Male',
  location: '',
  rescue_id: '',
  image: '',
  description: '',
  good_with_kids: false,
  good_with_dogs: false,
  good_with_cats: false,
};

const Admin = () => {
  const { user, isAdmin, isLoading: authLoading, signOut, isDevBypass } = useAuth();
  const { data: dogs = [], isLoading: dogsLoading, refetch } = useDogs();
  const { data: rescues = [] } = useRescues();
  const navigate = useNavigate();
  const { toast } = useToast();
  const queryClient = useQueryClient();
  
  const [isDialogOpen, setIsDialogOpen] = useState(false);
  const [editingDog, setEditingDog] = useState<Dog | null>(null);
  const [formData, setFormData] = useState<DogFormData>(initialFormData);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [imageFile, setImageFile] = useState<File | null>(null);
  const [imagePreview, setImagePreview] = useState<string | null>(null);
  const [isUploading, setIsUploading] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    if (!authLoading && !user) {
      navigate('/auth');
    }
  }, [user, authLoading, navigate]);

  useEffect(() => {
    if (!authLoading && user && !isAdmin) {
      toast({
        title: 'Access Denied',
        description: 'You do not have admin privileges.',
        variant: 'destructive'
      });
      navigate('/');
    }
  }, [isAdmin, authLoading, user, navigate, toast]);

  const handleOpenDialog = (dog?: Dog) => {
    if (dog) {
      setEditingDog(dog);
      // Find rescue_id from rescue name
      const rescue = rescues.find(r => r.name === dog.rescue);
      // Parse breeds from the breed string (could be comma-separated)
      const breeds = dog.breeds || (dog.breed ? dog.breed.split(',').map(b => b.trim()) : []);
      setFormData({
        name: dog.name,
        breeds: breeds,
        age: dog.age,
        size: dog.size,
        gender: dog.gender,
        location: dog.location,
        rescue_id: rescue?.id || '',
        image: dog.image,
        description: dog.description,
        good_with_kids: dog.goodWithKids,
        good_with_dogs: dog.goodWithDogs,
        good_with_cats: dog.goodWithCats,
      });
      setImagePreview(dog.image);
    } else {
      setEditingDog(null);
      setFormData(initialFormData);
      setImagePreview(null);
    }
    setImageFile(null);
    setIsDialogOpen(true);
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      if (!file.type.startsWith('image/')) {
        toast({ title: 'Error', description: 'Please select an image file', variant: 'destructive' });
        return;
      }
      if (file.size > 5 * 1024 * 1024) {
        toast({ title: 'Error', description: 'Image must be less than 5MB', variant: 'destructive' });
        return;
      }
      setImageFile(file);
      setImagePreview(URL.createObjectURL(file));
    }
  };

  const uploadImage = async (file: File): Promise<string> => {
    const fileExt = file.name.split('.').pop();
    const fileName = `${Date.now()}-${Math.random().toString(36).substring(2)}.${fileExt}`;
    
    const { error: uploadError } = await supabase.storage
      .from('dog-adopt-images')
      .upload(fileName, file);

    if (uploadError) throw uploadError;

    const { data: { publicUrl } } = supabase.storage
      .from('dog-adopt-images')
      .getPublicUrl(fileName);

    return publicUrl;
  };

  const clearImage = () => {
    setImageFile(null);
    setImagePreview(editingDog?.image || null);
    if (fileInputRef.current) {
      fileInputRef.current.value = '';
    }
  };

  const validateDogForm = (data: DogFormData): { isValid: boolean; error?: string } => {
    if (data.breeds.length === 0) {
      return { isValid: false, error: 'Please select at least one breed' };
    }
    return { isValid: true };
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);

    try {
      let imageUrl = formData.image;

      // Upload new image if selected
      if (imageFile) {
        setIsUploading(true);
        imageUrl = await uploadImage(imageFile);
        setIsUploading(false);
      }

      // Use default image if no image is provided
      if (!imageUrl) {
        imageUrl = DEFAULT_DOG_IMAGE;
      }

      // Validate form
      const validation = validateDogForm(formData);
      if (!validation.isValid) {
        toast({ title: 'Error', description: validation.error, variant: 'destructive' });
        setIsSubmitting(false);
        return;
      }

      const rescue = rescues.find(r => r.id === formData.rescue_id);
      
      const dogData = {
        name: formData.name,
        age: formData.age,
        size: formData.size,
        gender: formData.gender,
        rescue_id: formData.rescue_id || null,
        image: imageUrl,
        description: formData.description,
        good_with_kids: formData.good_with_kids,
        good_with_dogs: formData.good_with_dogs,
        good_with_cats: formData.good_with_cats,
      };

      let dogId: string;

      if (editingDog) {
        const { error } = await (supabase as any)
          .from('dogs')
          .update(dogData)
          .eq('id', editingDog.id);

        if (error) throw error;
        dogId = editingDog.id;
      } else {
        const { data: newDog, error } = await (supabase as any)
          .from('dogs')
          .insert([dogData])
          .select()
          .single();

        if (error) throw error;
        dogId = newDog.id;
      }

      // Update breeds using the helper function
      const { error: breedsError } = await (supabase as any).rpc(
        'set_dog_breeds',
        {
          p_dog_id: dogId,
          p_breed_names: formData.breeds
        }
      );

      if (breedsError) throw breedsError;

      toast({ 
        title: 'Success', 
        description: editingDog ? 'Dog updated successfully' : 'Dog added successfully' 
      });

      setIsDialogOpen(false);
      queryClient.invalidateQueries({ queryKey: ['dogs'] });
    } catch (error: any) {
      toast({
        title: 'Error',
        description: error.message || 'Something went wrong',
        variant: 'destructive'
      });
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleDelete = async (dogId: string) => {
    try {
      const { error } = await (supabase as any)
        .from('dogs')
        .delete()
        .eq('id', dogId);

      if (error) throw error;
      toast({ title: 'Success', description: 'Dog removed successfully' });
      queryClient.invalidateQueries({ queryKey: ['dogs'] });
    } catch (error: any) {
      toast({
        title: 'Error',
        description: error.message || 'Failed to delete dog',
        variant: 'destructive'
      });
    }
  };

  const handleSignOut = async () => {
    await signOut();
    navigate('/');
  };

  if (authLoading || dogsLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-background">
        <Loader2 className="w-8 h-8 animate-spin text-primary" />
      </div>
    );
  }

  if (!user || !isAdmin) {
    return null;
  }

  return (
    <div className="min-h-screen bg-background">
      {isDevBypass && <DevBypassBanner />}
      <header className="sticky top-0 z-50 bg-card/80 backdrop-blur-md border-b border-border">
        <div className="container mx-auto px-4">
          <div className="flex items-center justify-between h-16">
            <div className="flex items-center gap-4">
              <Button variant="ghost" size="icon" onClick={() => navigate('/')}>
                <ArrowLeft className="w-5 h-5" />
              </Button>
              <div className="flex items-center gap-2">
                <div className="w-10 h-10 rounded-full bg-primary flex items-center justify-center">
                  <Heart className="w-5 h-5 text-primary-foreground" fill="currentColor" />
                </div>
                <span className="font-display text-xl font-semibold text-foreground">
                  Admin Panel
                </span>
              </div>
            </div>
            <div className="flex items-center gap-4">
              <span className="text-sm text-muted-foreground">{user.email}</span>
              <Button variant="outline" size="sm" onClick={handleSignOut}>
                <LogOut className="w-4 h-4 mr-2" />
                Sign Out
              </Button>
            </div>
          </div>
        </div>
      </header>

      <main className="container mx-auto px-4 py-8">
        <div className="flex items-center justify-between mb-8">
          <h1 className="font-display text-3xl font-bold text-foreground">Manage Dogs</h1>
          <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
            <DialogTrigger asChild>
              <Button onClick={() => handleOpenDialog()}>
                <Plus className="w-4 h-4 mr-2" />
                Add Dog
              </Button>
            </DialogTrigger>
            <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
              <DialogHeader>
                <DialogTitle>{editingDog ? 'Edit Dog' : 'Add New Dog'}</DialogTitle>
              </DialogHeader>
              <form onSubmit={handleSubmit} className="space-y-4">
                <div className="space-y-2">
                  <Label htmlFor="name">Name</Label>
                  <Input
                    id="name"
                    value={formData.name}
                    onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                    required
                  />
                </div>

                <div className="space-y-2">
                  <Label>Breed(s)</Label>
                  <BreedCombobox
                    value={formData.breeds}
                    onChange={(breeds) => setFormData({ ...formData, breeds })}
                    placeholder="Select one or more breeds..."
                  />
                  <p className="text-xs text-muted-foreground">
                    Select multiple breeds for cross-breeds or mixes
                  </p>
                </div>

                <div className="grid grid-cols-3 gap-4">
                  <div className="space-y-2">
                    <Label htmlFor="age">Age</Label>
                    <Select value={formData.age} onValueChange={(v) => setFormData({ ...formData, age: v })}>
                      <SelectTrigger><SelectValue /></SelectTrigger>
                      <SelectContent>
                        <SelectItem value="Puppy">Puppy</SelectItem>
                        <SelectItem value="Young">Young</SelectItem>
                        <SelectItem value="Adult">Adult</SelectItem>
                        <SelectItem value="Senior">Senior</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="size">Size</Label>
                    <Select value={formData.size} onValueChange={(v) => setFormData({ ...formData, size: v })}>
                      <SelectTrigger><SelectValue /></SelectTrigger>
                      <SelectContent>
                        <SelectItem value="Small">Small</SelectItem>
                        <SelectItem value="Medium">Medium</SelectItem>
                        <SelectItem value="Large">Large</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="gender">Gender</Label>
                    <Select value={formData.gender} onValueChange={(v) => setFormData({ ...formData, gender: v })}>
                      <SelectTrigger><SelectValue /></SelectTrigger>
                      <SelectContent>
                        <SelectItem value="Male">Male</SelectItem>
                        <SelectItem value="Female">Female</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label htmlFor="rescue">Rescue Organisation</Label>
                    <RescueCombobox
                      value={formData.rescue_id}
                      onChange={(rescue_id) => {
                        // Auto-populate location with rescue's region when adding new dog
                        if (!editingDog) {
                          const selectedRescue = rescues.find(r => r.id === rescue_id);
                          if (selectedRescue) {
                            setFormData(prev => ({ ...prev, rescue_id, location: selectedRescue.region }));
                          } else {
                            setFormData(prev => ({ ...prev, rescue_id }));
                          }
                        } else {
                          setFormData(prev => ({ ...prev, rescue_id }));
                        }
                      }}
                      rescues={rescues}
                      placeholder="Select rescue organisation..."
                    />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="location">Location</Label>
                    <LocationCombobox
                      value={formData.location}
                      onChange={(location) => setFormData(prev => ({ ...prev, location }))}
                      placeholder="Select or enter location..."
                    />
                  </div>
                </div>

                <div className="space-y-2">
                  <Label>Dog Image (Optional)</Label>
                  <p className="text-xs text-muted-foreground">
                    If no image is uploaded, a default "Coming Soon" image will be used.
                  </p>
                  <div className="flex flex-col gap-3">
                    {imagePreview && (
                      <div className="relative w-32 h-32">
                        <img
                          src={imagePreview}
                          alt="Preview"
                          className="w-full h-full object-cover rounded-lg border border-border"
                        />
                        {imageFile && (
                          <Button
                            type="button"
                            variant="destructive"
                            size="icon"
                            className="absolute -top-2 -right-2 w-6 h-6"
                            onClick={clearImage}
                          >
                            <X className="w-3 h-3" />
                          </Button>
                        )}
                      </div>
                    )}
                    <div className="flex items-center gap-2">
                      <Input
                        ref={fileInputRef}
                        id="image"
                        type="file"
                        accept="image/*"
                        onChange={handleFileChange}
                        className="hidden"
                      />
                      <Button
                        type="button"
                        variant="outline"
                        onClick={() => fileInputRef.current?.click()}
                      >
                        <Upload className="w-4 h-4 mr-2" />
                        {imagePreview ? 'Change Image' : 'Upload Image'}
                      </Button>
                      {imageFile && (
                        <span className="text-sm text-muted-foreground truncate max-w-[200px]">
                          {imageFile.name}
                        </span>
                      )}
                    </div>
                  </div>
                </div>

                <div className="space-y-2">
                  <Label htmlFor="description">Description</Label>
                  <Textarea
                    id="description"
                    value={formData.description}
                    onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                    rows={3}
                    required
                  />
                </div>

                <div className="flex flex-wrap gap-6">
                  <div className="flex items-center gap-2">
                    <Checkbox
                      id="good_with_kids"
                      checked={formData.good_with_kids}
                      onCheckedChange={(c) => setFormData({ ...formData, good_with_kids: !!c })}
                    />
                    <Label htmlFor="good_with_kids">Good with kids</Label>
                  </div>
                  <div className="flex items-center gap-2">
                    <Checkbox
                      id="good_with_dogs"
                      checked={formData.good_with_dogs}
                      onCheckedChange={(c) => setFormData({ ...formData, good_with_dogs: !!c })}
                    />
                    <Label htmlFor="good_with_dogs">Good with dogs</Label>
                  </div>
                  <div className="flex items-center gap-2">
                    <Checkbox
                      id="good_with_cats"
                      checked={formData.good_with_cats}
                      onCheckedChange={(c) => setFormData({ ...formData, good_with_cats: !!c })}
                    />
                    <Label htmlFor="good_with_cats">Good with cats</Label>
                  </div>
                </div>

                <div className="flex justify-end gap-2 pt-4">
                  <Button type="button" variant="outline" onClick={() => setIsDialogOpen(false)}>
                    Cancel
                  </Button>
                  <Button type="submit" disabled={isSubmitting}>
                    {isSubmitting && <Loader2 className="w-4 h-4 animate-spin mr-2" />}
                    {editingDog ? 'Save Changes' : 'Add Dog'}
                  </Button>
                </div>
              </form>
            </DialogContent>
          </Dialog>
        </div>

        <div className="grid gap-4">
          {dogs.length === 0 ? (
            <Card>
              <CardContent className="py-8 text-center text-muted-foreground">
                No dogs yet. Click "Add Dog" to get started.
              </CardContent>
            </Card>
          ) : (
            dogs.map((dog) => (
              <Card key={dog.id}>
                <CardContent className="flex items-center gap-4 py-4">
                  <img
                    src={dog.image}
                    alt={dog.name}
                    className="w-16 h-16 rounded-lg object-cover"
                  />
                  <div className="flex-1 min-w-0">
                    <h3 className="font-display font-semibold text-foreground">{dog.name}</h3>
                    <p className="text-sm text-muted-foreground truncate">
                      {dog.breed} • {dog.age} • {dog.size} • {dog.location}
                    </p>
                    <p className="text-xs text-muted-foreground">{dog.rescue}</p>
                  </div>
                  <div className="flex gap-2">
                    <Button variant="outline" size="icon" onClick={() => handleOpenDialog(dog)}>
                      <Pencil className="w-4 h-4" />
                    </Button>
                    <AlertDialog>
                      <AlertDialogTrigger asChild>
                        <Button variant="outline" size="icon" className="text-destructive hover:text-destructive">
                          <Trash2 className="w-4 h-4" />
                        </Button>
                      </AlertDialogTrigger>
                      <AlertDialogContent>
                        <AlertDialogHeader>
                          <AlertDialogTitle>Delete {dog.name}?</AlertDialogTitle>
                          <AlertDialogDescription>
                            This action cannot be undone. This will permanently remove {dog.name} from the database.
                          </AlertDialogDescription>
                        </AlertDialogHeader>
                        <AlertDialogFooter>
                          <AlertDialogCancel>Cancel</AlertDialogCancel>
                          <AlertDialogAction onClick={() => handleDelete(dog.id)} className="bg-destructive text-destructive-foreground hover:bg-destructive/90">
                            Delete
                          </AlertDialogAction>
                        </AlertDialogFooter>
                      </AlertDialogContent>
                    </AlertDialog>
                  </div>
                </CardContent>
              </Card>
            ))
          )}
        </div>
      </main>
    </div>
  );
};

export default Admin;
