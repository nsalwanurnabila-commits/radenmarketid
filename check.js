
const SUPABASE_URL='https://zohhcndgfuvcugikqgwf.supabase.co';
const SUPABASE_PUBLISHABLE_KEY='sb_publishable_vgywxqEkFcMHXO4J5MRIIg_heYJcfQu';
const db=window.supabase.createClient(SUPABASE_URL,SUPABASE_PUBLISHABLE_KEY);
const $=id=>document.getElementById(id);let items=[],editing=null,chipFilter='all';
const esc=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const categoryOf=x=>String(x.category||'').trim()||inferCategory(x);
function inferCategory(x){const t=(String(x.name||'')+' '+String(x.description||'')).toLowerCase();const rules=[['AKUN TITIPAN',['titipan']],['EFOOTBALL',['efootball','e-football']],['FREE FIRE',['free fire','freefire',' ff ']],['PENZ',['penz']],['PUBG',['pubg']],['Rey MLBB',['rey mlbb']],['STOK ML ZUTO 1JT KEATAS',['zuto 1jt keatas','zuto 1jt ke atas']],['STOK ML ZUTO 1JT KEBAWAH',['zuto 1jt kebawah','zuto 1jt ke bawah']],['VALORANT',['valorant']],['MOBILE LEGENDS',['mobile legends','mlbb']]];for(const [c,keys] of rules)if(keys.some(k=>t.includes(k)))return c;return 'LAINNYA'}
const money=n=>new Intl.NumberFormat('id-ID',{style:'currency',currency:'IDR',maximumFractionDigits:0}).format(Number(n)||0);
function page(p){$('publicPage').classList.toggle('hidden',p!=='home');$('adminPage').classList.toggle('hidden',p!=='admin');$('navMenu').classList.remove('open');window.scrollTo({top:0,behavior:'smooth'})}
function render(){
 const q=$('search').value.toLowerCase().trim(),status=$('statusFilter').value,sort=$('sortFilter').value;
 const available=items.filter(x=>x.status==='available');
 $('stockCount').textContent=available.length;
 $('allCount').textContent=available.length;
 const cats=[...new Set(items.map(categoryOf))].sort((a,b)=>a.localeCompare(b,'id'));
 $('categoryChips').innerHTML=cats.map(c=>{const n=available.filter(x=>categoryOf(x)===c).length;return `<button class="chip ${chipFilter===c?'active':''}" data-filter="${esc(c)}">${esc(c)} <span>${n}</span></button>`}).join('');
 let list=items.filter(x=>(x.name+' '+(x.description||'')).toLowerCase().includes(q));
 if(status!=='all')list=list.filter(x=>x.status===status);
 if(chipFilter!=='all')list=list.filter(x=>categoryOf(x)===chipFilter);
 if(sort==='low')list.sort((a,b)=>Number(a.price)-Number(b.price));
 if(sort==='high')list.sort((a,b)=>Number(b.price)-Number(a.price));
 $('resultCount').textContent=list.length+' akun ditemukan';
 $('productGrid').innerHTML=list.length?list.map(x=>`<article class="card"><div class="cover">${x.image_url?`<img src="${esc(x.image_url)}" alt="Foto ${esc(x.name)}" onerror="this.parentElement.textContent='🎮'">`:'🎮'}</div><div class="cardbody"><span class="tag ${x.status==='sold'?'sold':''}">${x.status==='sold'?'Terjual':'Tersedia'}</span><h3>${esc(x.name)}</h3><div class="desc">${esc(x.description||'Detail akun dapat ditanyakan kepada admin.')}</div><div class="price-line"><div><div class="price-label">Harga akun</div><div class="price">${money(x.price)}</div></div><button class="detail" onclick="contactAdminForItem(${JSON.stringify(String(x.id))})">Detail ↗</button></div></div></article>`).join(''):'<div class="empty">Belum ada akun yang cocok dengan pencarianmu.</div>';
 if(!$('dashboard').classList.contains('hidden'))adminList();
}
window.contactAdminForItem=id=>{
 const x=items.find(v=>String(v.id)===String(id));if(!x)return;
 const photo=x.image_url?new URL(x.image_url,window.location.origin).href:'Foto akun belum tersedia di katalog.';
 const message=[
  'Halo Admin RadenMarket, saya ingin menanyakan stok akun ini.',
  '',
  'Nama akun: '+x.name,
  'Kategori: '+categoryOf(x),
  'Harga katalog: '+money(x.price),
  'Status di katalog: '+(x.status==='sold'?'Terjual':'Tersedia'),
  'Keterangan: '+(x.description||'-'),
  'Foto akun: '+photo,
  '',
  'Apakah akun ini masih ready? Mohon konfirmasi stok terbarunya. Terima kasih.'
 ].join('\\n');
 const url='https://wa.me/6285813987501?text='+encodeURIComponent(message);
 window.open(url,'_blank','noopener,noreferrer');
};
async function load(){let {data,error}=await db.from('ff_accounts').select('*').order('created_at',{ascending:false});if(error){$('productGrid').innerHTML='<div class="empty">Gagal memuat stok. Periksa koneksi dan kebijakan RLS.</div>';console.error(error);$('resultCount').textContent='Database belum terhubung';return}items=data||[];render()}
function adminList(){$('adminList').innerHTML=items.length?items.map(x=>`<div class="adminrow"><div><b>${esc(x.name)}</b><div class="small">${money(x.price)} · ${esc(categoryOf(x))} · ${x.status==='sold'?'Terjual':'Tersedia'}</div></div><div class="actions"><button class="secondary" onclick="editItem(${JSON.stringify(String(x.id))})">Edit</button><button class="danger" onclick="deleteItem(${JSON.stringify(String(x.id))})">Hapus</button></div></div>`).join(''):'<p class="small">Belum ada stok.</p>'}
function reset(){editing=null;['itemName','itemCategory','itemPrice','itemImage','itemDesc'].forEach(id=>$(id).value='');$('itemStatus').value='available';$('formTitle').textContent='Tambah stok akun';$('saveBtn').textContent='Simpan stok';$('cancelEdit').classList.add('hidden')}
window.editItem=id=>{let x=items.find(v=>String(v.id)===String(id));if(!x)return;editing=x.id;$('itemName').value=x.name;$('itemCategory').value=categoryOf(x);$('itemPrice').value=x.price;$('itemStatus').value=x.status;$('itemImage').value=x.image_url||'';$('itemDesc').value=x.description||'';$('formTitle').textContent='Edit stok akun';$('saveBtn').textContent='Simpan perubahan';$('cancelEdit').classList.remove('hidden');window.scrollTo({top:0,behavior:'smooth'})};
window.deleteItem=async id=>{if(!confirm('Hapus stok ini?'))return;let {error}=await db.from('ff_accounts').delete().eq('id',id);if(error){alert(error.message);return}await load()};
async function authUI(){let {data}=await db.auth.getSession();let recovery=location.hash.includes('type=recovery')||new URLSearchParams(location.search).get('type')==='recovery';if(recovery){$('loginSection').classList.remove('hidden');$('dashboard').classList.add('hidden');$('newPasswordSection').classList.remove('hidden');$('loginMsg').textContent='Buat password baru untuk akun admin.';return}let yes=!!data.session;$('loginSection').classList.toggle('hidden',yes);$('dashboard').classList.toggle('hidden',!yes);if(yes)await load()}
$('homeBtn').onclick=()=>page('home');$('adminBtn').onclick=()=>page('admin');$('menuBtn').onclick=()=>$('navMenu').classList.toggle('open');
$('search').oninput=render;$('searchBtn').onclick=render;$('statusFilter').onchange=render;$('sortFilter').onchange=render;
$('chips').addEventListener('click',e=>{const b=e.target.closest('[data-filter]');if(!b)return;chipFilter=b.dataset.filter;document.querySelectorAll('.chip').forEach(x=>x.classList.toggle('active',x===b));render()});
$('resetBtn').onclick=()=>{$('search').value='';$('statusFilter').value='all';$('sortFilter').value='new';chipFilter='all';document.querySelectorAll('.chip').forEach((x,i)=>x.classList.toggle('active',i===0));render()};
$('forgotBtn').onclick=async()=>{const email=$('emailInput').value.trim();if(!email){$('loginMsg').textContent='Masukkan email admin terlebih dahulu.';return}const {error}=await db.auth.resetPasswordForEmail(email,{redirectTo:window.location.origin});$('loginMsg').textContent=error?'Gagal mengirim email: '+error.message:'Link pemulihan password sudah dikirim. Periksa inbox atau folder Spam.'};
$('updatePasswordBtn').onclick=async()=>{const p=$('newPasswordInput').value,c=$('confirmPasswordInput').value;if(p.length<8){$('passwordMsg').textContent='Password minimal 8 karakter.';return}if(p!==c){$('passwordMsg').textContent='Konfirmasi password tidak sama.';return}const {error}=await db.auth.updateUser({password:p});$('passwordMsg').textContent=error?'Gagal mengubah password: '+error.message:'Password berhasil diperbarui. Silakan login dengan password baru.';if(!error){$('newPasswordInput').value='';$('confirmPasswordInput').value='';await db.auth.signOut();$('newPasswordSection').classList.add('hidden');$('loginSection').classList.remove('hidden')}};
$('loginBtn').onclick=async()=>{let {error}=await db.auth.signInWithPassword({email:$('emailInput').value.trim(),password:$('passwordInput').value});$('loginMsg').textContent=error?'Login gagal: '+error.message:'Login berhasil';if(!error)await authUI()};
$('logoutBtn').onclick=async()=>{await db.auth.signOut();reset();await authUI()};
$('saveBtn').onclick=async()=>{let name=$('itemName').value.trim(),price=Number($('itemPrice').value);if(!name||$('itemPrice').value===''||!Number.isFinite(price)||price<0){$('formMsg').textContent='Isi nama akun dan harga dengan benar.';return}let category=$('itemCategory').value.trim();if(!category){$('formMsg').textContent='Isi kategori akun agar stok dapat dihitung per kategori.';return}let row={name,category,price,status:$('itemStatus').value,image_url:$('itemImage').value.trim()||null,description:$('itemDesc').value.trim()};let result=editing?await db.from('ff_accounts').update(row).eq('id',editing):await db.from('ff_accounts').insert(row);if(result.error){$('formMsg').textContent='Gagal menyimpan: '+result.error.message;return}reset();$('formMsg').textContent='Stok tersimpan.';await load()};
$('cancelEdit').onclick=reset;$('year').textContent=new Date().getFullYear();db.auth.onAuthStateChange((event)=>{if(event==='PASSWORD_RECOVERY'){$('loginSection').classList.remove('hidden');$('dashboard').classList.add('hidden');$('newPasswordSection').classList.remove('hidden');$('loginMsg').textContent='Buat password baru untuk akun admin.'}else authUI()});load();authUI();setInterval(load,20000);
