import * as React from 'react'
import { Settings } from 'lucide-react'
import type { ServiceAccount } from '@/lib/fcm'
import { loadFCMConfig, saveFCMConfig } from '@/lib/fcm'
import { Button } from '@/components/ui/button'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from '@/components/ui/dialog'
import { Label } from '@/components/ui/label'

const SA_PLACEHOLDER = `{
  "type": "service_account",
  "project_id": "your-project",
  "private_key_id": "...",
  "private_key": "-----BEGIN PRIVATE KEY-----\\n...\\n-----END PRIVATE KEY-----\\n",
  "client_email": "firebase-adminsdk-...@your-project.iam.gserviceaccount.com",
  ...
}`

interface Props {
  children?: React.ReactNode
}

export function FCMSettingsDialog({ children }: Props) {
  const [open, setOpen] = React.useState(false)
  const [saJson, setSaJson] = React.useState('')
  const [deviceToken, setDeviceToken] = React.useState('')
  const [saved, setSaved] = React.useState(false)
  const [error, setError] = React.useState<string | null>(null)

  React.useEffect(() => {
    if (open) {
      const stored = loadFCMConfig()
      if (stored) {
        setSaJson(JSON.stringify(stored.serviceAccount, null, 2))
        setDeviceToken(stored.deviceToken)
      }
      setSaved(false)
      setError(null)
    }
  }, [open])

  function handleSave() {
    setError(null)
    let sa: ServiceAccount
    try {
      sa = JSON.parse(saJson) as ServiceAccount
    } catch {
      setError('Invalid JSON — check the format and try again.')
      return
    }
    if (!sa.project_id || !sa.private_key || !sa.client_email) {
      setError(
        'Service account must have project_id, private_key, and client_email.',
      )
      return
    }
    if (!sa.private_key.includes('BEGIN PRIVATE KEY')) {
      setError('private_key does not look like a PEM key.')
      return
    }
    if (!deviceToken.trim()) {
      setError('Device token is required. Copy it from the Android app.')
      return
    }
      saveFCMConfig({ serviceAccount: sa, deviceToken: deviceToken.trim() })
    setSaved(true)
    setTimeout(() => setOpen(false), 600)
  }

  const canSave = saJson.trim() && deviceToken.trim()

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        {children ?? (
          <Button
            variant="ghost"
            size="icon"
            aria-label="FCM settings"
            className="text-muted-foreground hover:text-foreground"
          >
            <Settings className="size-5" />
          </Button>
        )}
      </DialogTrigger>

      <DialogContent className="max-w-sm">
        <DialogHeader>
          <DialogTitle>Remote Push Settings</DialogTitle>
          <DialogDescription>
            Sends triggers via{' '}
            <a
              href="https://firebase.google.com/docs/cloud-messaging"
              target="_blank"
              rel="noopener noreferrer"
              className="underline"
            >
              Firebase Cloud Messaging
            </a>
            . Stateless — FCM wakes the Android app even when it&apos;s killed.
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-3">
          <div className="space-y-1.5">
            <Label htmlFor="sa-json">Service Account JSON</Label>
            <textarea
              id="sa-json"
              rows={7}
              placeholder={SA_PLACEHOLDER}
              value={saJson}
              onChange={(e) => {
                setSaJson(e.target.value)
                setError(null)
              }}
              spellCheck={false}
              className="border-input bg-background ring-offset-background placeholder:text-muted-foreground focus-visible:ring-ring w-full rounded-md border px-3 py-2 font-mono text-xs shadow-xs transition-colors focus-visible:ring-1 focus-visible:outline-none resize-none"
            />
            <p className="text-muted-foreground text-xs">
              Firebase Console → Project Settings → Service accounts → Generate
              new private key.
            </p>
          </div>

          <div className="space-y-1.5">
            <Label htmlFor="device-token">Device Token</Label>
            <input
              id="device-token"
              type="text"
              placeholder="Paste the FCM token from the Android app"
              value={deviceToken}
              onChange={(e) => {
                setDeviceToken(e.target.value)
                setError(null)
              }}
              autoComplete="off"
              spellCheck={false}
              className="border-input bg-background ring-offset-background placeholder:text-muted-foreground focus-visible:ring-ring flex h-9 w-full rounded-md border px-3 py-1 text-sm shadow-xs transition-colors focus-visible:ring-1 focus-visible:outline-none"
            />
            <p className="text-muted-foreground text-xs">
              Shown in the Android app under Remote Push settings — tap Copy
              Token.
            </p>
          </div>

          {error && <p className="text-destructive text-xs">{error}</p>}
        </div>

        <DialogFooter>
          <Button onClick={handleSave} disabled={!canSave} className="w-full">
            {saved ? 'Saved!' : 'Save'}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
